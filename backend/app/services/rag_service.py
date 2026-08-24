"""
rag_service.py — Versão Estabilizada e Sincronizada
"""

import os
import json
import logging
import asyncio
import uuid
import re
from typing import Annotated, List, Dict, Optional, TypedDict, Any, Sequence

# LangChain, NVIDIA & Groq
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_groq import ChatGroq
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool

# LangGraph
from langgraph.graph import StateGraph, END, START
from langgraph.checkpoint.memory import MemorySaver
from langchain_core.runnables import RunnableConfig

from app.core.config import settings
from app.services.agent_tools import execute_tool
from app.services.conversation_state import conversation_manager, validate_cpf, looks_like_cpf
from app.services.standard_messages import (
    get_cpf_request_message, get_cpf_invalid_message,
    get_cpf_confirmed_message, get_cpf_not_found_message,
    detect_cpf_required_intent, get_footer_message
)

logger = logging.getLogger(__name__)

from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], add_messages]
    wa_from: str
    wa_to: str
    doctor_info: Optional[dict]
    active_doctor_id: Optional[int]
    active_doctor_name: Optional[str]
    last_search_type: Optional[str]
    next_node: str
    loop_count: int
    user_role: Optional[str]
    user_name: Optional[str]
    user_id: Optional[int]
    patient_id: Optional[int]

# Tools LangChain (Mapeamento Simples)
@tool
def buscar_faq_tool(pergunta: str):
    """Dúvidas gerais, convênios e pagamentos."""
    from app.services.agent_tools import buscar_faq
    return buscar_faq(pergunta=pergunta)

@tool
def buscar_medico_tool(nome: str = None, especialidade: str = None):
    """Informações sobre médicos da clínica."""
    from app.services.agent_tools import buscar_medico
    return buscar_medico(nome=nome, especialidade=especialidade)

@tool
def buscar_horarios_tool(medico_id: int = None, nome_medico: str = None):
    """Agenda de horários disponíveis e consulta de disponibilidade para agendamento."""
    from app.services.agent_tools import buscar_horarios
    return buscar_horarios(medico_id=medico_id, nome_medico=nome_medico)

@tool
def agendar_consulta_tool(medico_id: int, data_hora: Optional[str] = None, cpf: Optional[str] = None, patient_name: Optional[str] = None, patient_id: Optional[int] = None, motivo: str = "Consulta via WhatsApp"):
    """Agenda uma consulta/retorno para um paciente."""
    from app.services.agent_tools import agendar_consulta
    return agendar_consulta(medico_id=medico_id, data_hora=data_hora, cpf=cpf, patient_name=patient_name, patient_id=patient_id, motivo=motivo)

@tool
def cancelar_consulta_tool(data_hora: str, cpf: str = None):
    """
    Cancela o agendamento de uma consulta no banco de dados.
    Use quando o paciente pedir para cancelar ou desmarcar uma consulta.
    A data_hora deve ser no formato ISO (AAAA-MM-DD HH:MM).
    """
    return "Cancelamento em processamento..."

@tool
def buscar_agendamentos_tool(cpf: Optional[str] = None, patient_id: Optional[int] = None):
    """
    Busca os agendamentos (consultas e exames) de um paciente.
    Pode buscar pelo CPF ou pelo ID do paciente.
    Use esta ferramenta quando o usuário perguntar 'quais são minhas consultas', 'quando é meu próximo exame' ou similar.
    """
    from app.services.agent_tools import buscar_agendamentos
    # wa_from será injetado pelo orchestrator se necessário, aqui focamos nos params da LLM
    return buscar_agendamentos(cpf=cpf, patient_id=patient_id)

@tool
def buscar_consultas_medico_tool(medico_id: int):
    """Busca as próximas consultas (agendamentos) de um médico."""
    return "Buscando consultas do médico..."

@tool
def buscar_info_paciente_tool(nome_ou_cpf: str):
    """Busca informações de um paciente e seus exames pelo nome ou CPF."""
    return "Buscando informações do paciente..."

langchain_tools = [
    buscar_faq_tool, 
    buscar_medico_tool, 
    buscar_horarios_tool, 
    agendar_consulta_tool, 
    cancelar_consulta_tool, 
    buscar_agendamentos_tool,
    buscar_consultas_medico_tool, 
    buscar_info_paciente_tool
]

class RAGService:
    def __init__(self):
        # Define patient tools to prevent the patient assistant LLM from having access to sensitive tools
        patient_tools = [
            buscar_faq_tool, 
            buscar_medico_tool, 
            buscar_horarios_tool, 
            agendar_consulta_tool, 
            cancelar_consulta_tool, 
            buscar_agendamentos_tool
        ]

        # Configuração de Modelos (Upgrade para 70B para garantir estabilidade nas ferramentas)
        if settings.GROQ_API_KEY:
            self.llm = ChatGroq(model="llama-3.3-70b-versatile", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=600).bind_tools(patient_tools)
            self.llm_base = ChatGroq(model="llama-3.3-70b-versatile", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=600)
        else:
            self.llm = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1).bind_tools(patient_tools)
            self.llm_base = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1)

        self._setup_graph()
        self.memory = MemorySaver()
        self.app = self.graph.compile(checkpointer=self.memory)

    def _setup_graph(self):
        workflow = StateGraph(AgentState)
        workflow.add_node("triage", self._triage_node)
        workflow.add_node("agent", self._agent_node)
        workflow.add_node("tools", self._tools_node)
        workflow.add_node("force_search", self._force_search_node)
        workflow.add_node("cpf_flow", self._cpf_node)

        workflow.add_edge(START, "triage")
        workflow.add_edge("force_search", "agent")
        workflow.add_conditional_edges("triage", self._triage_router, {"cpf_flow": "cpf_flow", "agent": "agent", "force_search": "force_search", "menu": END})
        workflow.add_edge("cpf_flow", END)
        workflow.add_conditional_edges("agent", self._agent_router, {"continue": "tools", "end": END})
        workflow.add_edge("tools", "agent")
        self.graph = workflow

    def _triage_node(self, state: AgentState, config: RunnableConfig = None):
        query = state["messages"][-1].content.strip().lower()
        wa_from = state["wa_from"]
        state["loop_count"] = 0

        # Persistência de Contexto (Dinâmico)
        from app.models.medico import Medico
        db = config["configurable"].get("db") if config else None
        if db:
            try:
                medicos = db.query(Medico).filter(Medico.ativo == True).all()
                for m in medicos:
                    parts = m.nome_completo.lower().split()
                    if any(p in query for p in parts if len(p) > 3):
                        state["active_doctor_id"], state["active_doctor_name"] = m.id, m.nome_completo
                        break
            except Exception as e:
                logger.error(f"Erro ao buscar médicos no triage: {e}")
        
        if any(k in query for k in ["valor", "preço"]): state["last_search_type"] = "valor"
        elif any(k in query for k in ["parcela", "pagamento"]): state["last_search_type"] = "pagamento"
        elif any(k in query for k in ["convênio", "aceita"]): state["last_search_type"] = "convênio"

        user_role = state.get("user_role", "patient")
        if user_role == "doctor":
            # Médicos e funcionários vão DIRETO para o agente para evitar regras rígidas de pacientes
            return {"next_node": "agent"}

        if query in ("0", "x", "sair"): 
            return {"next_node": "menu"}
        if conversation_manager.is_awaiting_cpf(wa_from): 
            return {"next_node": "cpf_flow"}
        
        # OBRIGATÓRIO: Retornar os campos alterados para atualizar o State do LangGraph
        result = {
            "active_doctor_id": state.get("active_doctor_id"),
            "active_doctor_name": state.get("active_doctor_name"),
            "last_search_type": state.get("last_search_type"),
            "loop_count": 0
        }

        if any(k in query for k in ['médico', 'medico', 'doutor', 'dra', 'dr', 'datas', 'horários', 'valor', 'parcela', 'convênio']):
            result["next_node"] = "force_search"
        else:
            result["next_node"] = "agent"
            
        return result

    def _triage_router(self, state: AgentState):
        next_node = state.get("next_node", "agent")
        logger.info(f"[_triage_router] next_node: {next_node}")
        return next_node

    def _cpf_node(self, state: AgentState, config: RunnableConfig = None):
        query = state["messages"][-1].content
        wa_from = state["wa_from"]
        db = config["configurable"].get("db")
        if conversation_manager.is_awaiting_cpf(wa_from):
            cpf_val = validate_cpf(query)
            if cpf_val:
                from app.models.patient import Patient
                patient = db.query(Patient).filter(Patient.cpf == cpf_val).first()
                if patient:
                    conversation_manager.set_cpf(wa_from, cpf_val)
                    op = conversation_manager.get_pending_operation(wa_from)
                    conversation_manager.clear_cpf_flow(wa_from)
                    return {"messages": [AIMessage(content=get_cpf_confirmed_message(patient.name, op))]}
                else:
                    return {"messages": [AIMessage(content=get_cpf_not_found_message())]}
            return {"messages": [AIMessage(content=get_cpf_invalid_message())]}
        return {"messages": [AIMessage(content=get_cpf_request_message("atendimento"))]}

    async def _agent_node(self, state: AgentState, config: RunnableConfig = None):
        all_messages = state["messages"]
        last_is_tool = len(all_messages) > 0 and isinstance(all_messages[-1], ToolMessage)

        # Prompt baseado no papel do usuário (2 IAs distintas)
        user_role = state.get("user_role", "patient")
        user_name = state.get("user_name", "")
        user_id = state.get("user_id")
        
        if user_role == "doctor":
            # IA 2: Assistente do Médico
            # Buscar o ID do médico logado
            doctor_id = None
            db = config["configurable"].get("db")
            if db and user_id:
                from app.models.medico import Medico
                medico = db.query(Medico).filter(Medico.user_id == user_id).first()
                if medico:
                    doctor_id = medico.id
                    logger.info(f"[_agent_node] Encontrado Médico ID: {doctor_id} para User ID: {user_id}")

            # Vincula apenas as ferramentas relevantes para o médico
            doctor_tools = [buscar_consultas_medico_tool, buscar_info_paciente_tool, agendar_consulta_tool]
            if settings.GROQ_API_KEY:
                doctor_llm = ChatGroq(model="llama-3.3-70b-versatile", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=400).bind_tools(doctor_tools)
            else:
                doctor_llm = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1).bind_tools(doctor_tools)
            
            patient_id = state.get("patient_id")
            sys_prompt = (
                f"Você é o Assistente Pessoal do(a) Dr(a). {user_name or 'Médico'}. 🩺\n"
                f"Hoje é {datetime.now().strftime('%A, %Y-%m-%d %H:%M')} (use isso como referência para datas relativas como 'segunda', 'amanhã').\n"
                f"Seu ID de médico é {doctor_id or 'desconhecido'}. Sempre use este ID quando chamar ferramentas que exigem `medico_id`.\n"
                "Você o ajuda a gerenciar sua agenda e pacientes.\n"
                "Se o usuário disser 'segunda' ou 'amanhã', calcule a data correta e passe no formato AAAA-MM-DD HH:MM para a ferramenta.\n"
                "Se ele pedir para agendar um retorno ou consulta, você DEVE usar a ferramenta agendar_consulta_tool. Você pode identificar o paciente por CPF, ID ou NOME (passando no parâmetro `patient_name`).\n"
                "Você PODE chamar a ferramenta `agendar_consulta_tool` mesmo sem a data (deixe o parâmetro `data_hora` vazio ou nulo). A ferramenta irá buscar o paciente no banco de dados e retornar a mensagem de confirmação adequada ou pedirá a data.\n"
                "NÃO invente datas, horários ou CPFs sob nenhuma circunstância! Se o usuário não passou esses dados, deixe-os vazios para a ferramenta.\n"
                "Se ele pedir informações sobre as próximas consultas dele, use a ferramenta buscar_consultas_medico_tool.\n"
                "Se ele pedir informações sobre pacientes ou exames, use a ferramenta buscar_info_paciente_tool.\n"
                "Responda de forma profissional, direta e prestativa. Você NÃO é a Isis."
            )
            messages = [SystemMessage(content=sys_prompt)] + list(state["messages"])[-6:]
            try:
                response = await asyncio.wait_for(doctor_llm.ainvoke(messages), timeout=45)
                return {"messages": [response]}
            except Exception as e:
                logger.error(f"Erro no Doctor Agent: {e}")
                return {"messages": [AIMessage(content="Desculpe Doutor, tive um erro ao processar sua solicitação.")]}
        
        else:
            patient_id = state.get("patient_id")
            sys_prompt = (
                "Você é a Isis, assistente virtual doce, prestativa e organizada da clínica. ✨\n"
                f"O usuário está LOGADO. Nome: {user_name or 'Paciente'}. ID do Paciente: {patient_id or 'desconhecido'}.\n"
                "Sempre trate o paciente pelo nome. Como ele está logado, você JÁ TEM acesso aos agendamentos dele via ferramenta `buscar_agendamentos`. NÃO peça CPF.\n"
                "REGRA DE OURO 1: Você SÓ fala sobre assuntos da clínica (médicos, horários, exames, convênios e saúde).\n"
                "REGRA DE OURO 2: Os resultados das ferramentas SÃO INVISÍVEIS para o paciente! Você DEVE ler os dados retornados e ESCREVÊ-LOS na sua resposta.\n"
                "REGRA DE OURO 3: Quando listar médicos, especialidades ou horários, você DEVE sempre usar formato de tópicos (bullet points) com marcadores, um por linha.\n"
                "REGRA DE OURO 4: NUNCA invente ou presuma informações sobre pagamentos, parcelamentos, convênios ou políticas da clínica se não estiverem EXPLICITAMENTE escritas nos dados das ferramentas. Se os dados não mencionarem parcelamento, diga EXATAMENTE: 'Desculpe, não tenho as opções de parcelamento aqui. Por favor, fale com nossa recepção! ✨'. NUNCA assuma que 'não parcela'.\n"
                "Se o usuário pedir para cancelar uma consulta, use a ferramenta de cancelar_consulta. Se pedir para remarcar, cancele a anterior e agende a nova.\n"
                "Se o usuário perguntar sobre QUALQUER outro assunto, negue educadamente.\n"
                "REGRA CRÍTICA: Se uma ferramenta pedir um CPF e você não souber o do paciente, NÃO invente um número! Use o patient_id."
            )
            active_doc = state.get("active_doctor_name")
            active_id = state.get("active_doctor_id")
            context = f"\n[Contexto: Médico {active_doc or 'Geral'} (ID: {active_id or 'Não selecionado'})]"
            
            messages = [SystemMessage(content=sys_prompt + context)] + list(state["messages"])[-6:]
            
            try:
                logger.info(f"[Agent] Enviando {len(messages)} mensagens para a LLM...")
                response = await asyncio.wait_for(self.llm.ainvoke(messages), timeout=45)
                logger.info(f"[Agent] Resposta recebida da LLM: {response.content[:50]}...")
                
                content = response.content
                if any(k in content.lower() for k in ["localhost", "11434", "ollama", "aula", ".pdf"]):
                    return {"messages": [AIMessage(content="Sabe o que é? Não localizei essa info exata agora. 😅 Por favor, fale com nossa recepção! ✨")]}
                return {"messages": [response]}
            except Exception as e:
                logger.error(f"ERRO NA CHAMADA DA LLM (Groq): {e}", exc_info=True)
                return {"messages": [AIMessage(content=f"Puxa, tive um erro técnico aqui (IA): {str(e)}")]}

    def _force_search_node(self, state: AgentState, config: RunnableConfig = None):
        """Busca automática com separação rígida de intenções."""
        query = state["messages"][-1].content.lower()
        db = config["configurable"].get("db")
        target_id = state.get("active_doctor_id")

        # 1. VALOR / PREÇO (Prioridade: Banco de Médicos)
        if any(k in query for k in ["valor", "preço", "quanto", "custo"]):
            logger.info("[Force Search] Intenção de VALOR detectada.")
            args = {"nome": state.get("active_doctor_name")} if target_id else {}
            res = execute_tool("buscar_medico", args, db, wa_from=state["wa_from"], patient_id=state.get("patient_id"), user_role=state.get("user_role"))
            tid = f"m_{uuid.uuid4().hex[:4]}"
            return {"messages": [
                AIMessage(content="", tool_calls=[{"name": "buscar_medico_tool", "args": args, "id": tid}]),
                ToolMessage(tool_call_id=tid, content=res, name="buscar_medico_tool")
            ]}

        # 2. PARCELAMENTO / PAGAMENTO / CONVÊNIO
        if any(k in query for k in ["parcela", "pagamento", "pix", "cartão", "convênio", "convenio"]):
            logger.info("[Force Search] Intenção FINANCEIRA/CONVÊNIO detectada.")
            
            # Se a dúvida for sobre CONVÊNIOS, buscamos nos MÉDICOS primeiro (onde estão os dados reais)
            if "convênio" in query or "convenio" in query:
                res_medicos = execute_tool("buscar_medico", {}, db, wa_from=state["wa_from"], patient_id=state.get("patient_id"), user_role=state.get("user_role"))
                res_faq = execute_tool("buscar_faq", {"pergunta": "Quais os convênios aceitos?"}, db, wa_from=state["wa_from"], user_role=state.get("user_role"))
                
                # Agregamos os dois para uma resposta completa
                tid_m, tid_f = f"m_{uuid.uuid4().hex[:4]}", f"f_{uuid.uuid4().hex[:4]}"
                return {
                    "messages": [
                        AIMessage(content="", tool_calls=[
                            {"name": "buscar_medico_tool", "args": {}, "id": tid_m},
                            {"name": "buscar_faq_tool", "args": {"pergunta": "Quais os convênios aceitos?"}, "id": tid_f}
                        ]),
                        ToolMessage(tool_call_id=tid_m, content=res_medicos, name="buscar_medico_tool"),
                        ToolMessage(tool_call_id=tid_f, content=res_faq, name="buscar_faq_tool")
                    ]
                }

            # Se for apenas parcelamento
            pergunta = "Formas de pagamento e parcelamento?" if "parcela" in query else "Formas de pagamento?"
            res = execute_tool("buscar_faq", {"pergunta": pergunta}, db, wa_from=state["wa_from"], user_role=state.get("user_role"))
            if not res or "Nenhuma informação" in res or len(res) < 15:
                return {"messages": [AIMessage(content="Não tenho os detalhes de parcelamento aqui. 😅 Por favor, fale com nossa recepção! ✨")]}
            tid = f"f_{uuid.uuid4().hex[:4]}"
            return {"messages": [
                AIMessage(content="", tool_calls=[{"name": "buscar_faq_tool", "args": {"pergunta": pergunta}, "id": tid}]),
                ToolMessage(tool_call_id=tid, content=res, name="buscar_faq_tool")
            ]}

        # 3. DATAS / HORÁRIOS
        if any(k in query for k in ["datas", "horários", "horario", "os dois", "ambos"]):
            if not target_id or any(k in query for k in ["todos", "ambos", "os dois"]):
                from app.models.medico import Medico
                medicos = db.query(Medico).filter(Medico.ativo == True).limit(3).all()
                tool_calls = []
                messages = []
                for i, m in enumerate(medicos):
                    tid = f"b{i}_{uuid.uuid4().hex[:4]}"
                    args = {"medico_id": m.id}
                    res = execute_tool("buscar_horarios", args, db, wa_from=state["wa_from"], patient_id=state.get("patient_id"), user_role=state.get("user_role"))
                    tool_calls.append({"name": "buscar_horarios_tool", "args": args, "id": tid})
                    messages.append(ToolMessage(tool_call_id=tid, content=res, name="buscar_horarios_tool"))
                return {"messages": [AIMessage(content="", tool_calls=tool_calls)] + messages}
            
            args = {"medico_id": target_id}
            res = execute_tool("buscar_horarios", args, db, wa_from=state["wa_from"], patient_id=state.get("patient_id"), user_role=state.get("user_role"))
            tid = f"c_{uuid.uuid4().hex[:4]}"
            return {"messages": [
                AIMessage(content="", tool_calls=[{"name": "buscar_horarios_tool", "args": args, "id": tid}]),
                ToolMessage(tool_call_id=tid, content=res, name="buscar_horarios_tool")
            ]}

        # 4. MÉDICOS
        if any(k in query for k in ['médico', 'medico', 'doutor', 'dra', 'dr', 'especialista']):
            nome_medico = state.get("active_doctor_name")
            args = {"nome": nome_medico} if nome_medico else {}
            res = execute_tool("buscar_medico", args, db, wa_from=state["wa_from"], user_role=state.get("user_role"))
            tid = f"m_{uuid.uuid4().hex[:4]}"
            return {"messages": [
                AIMessage(content="", tool_calls=[{"name": "buscar_medico_tool", "args": args, "id": tid}]),
                ToolMessage(tool_call_id=tid, content=res, name="buscar_medico_tool")
            ]}

        return {"messages": [AIMessage(content="Não localizei essa informação específica. 😅 Por favor, fale com nossa recepção! ✨")]}

    def _tools_node(self, state: AgentState, config: RunnableConfig = None):
        last_msg = state["messages"][-1]
        results = []
        db = config["configurable"].get("db")
        for tc in last_msg.tool_calls:
            res = execute_tool(
                tc["name"].replace("_tool",""), 
                tc["args"], 
                db, 
                wa_from=state["wa_from"], 
                patient_id=state.get("patient_id"), 
                user_role=state.get("user_role")
            )
            results.append(ToolMessage(tool_call_id=tc["id"], content=str(res)))
        # Incrementa loop_count aqui, pois o nó é persistido no estado do LangGraph!
        return {"messages": results, "loop_count": state.get("loop_count", 0) + 1}

    def _agent_router(self, state: AgentState):
        last_msg = state["messages"][-1]
        if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
            # loop_count agora é incrementado de forma persistente dentro do _tools_node!
            return "continue" if state.get("loop_count", 0) <= 1 else "end"
        return "end"

    async def get_rag_response(self, query: str, wa_to: str, db, wa_from: str = "anonymous", source: str = "whatsapp", user_name: str = None, user_id: int = None, patient_id: int = None) -> str:
        if query.lower() in ["reset", "limpar"]:
            self.clear_conversation(wa_from)
            return "Sessão reiniciada! ✨"
        
        # Fasttrack para saudações no app (zero latência e sem alucinação)
        saudacoes = ["oi", "olá", "ola", "bom dia", "boa tarde", "boa noite", "tudo bem", "ok", "bem", "oie"]
        import re
        query_clean = re.sub(r'[^\w\s]', '', query.lower()).strip()
        
        # Log de debug para o fasttrack
        logger.info(f"[FastTrack] Source: {source}, Query: '{query_clean}'")
        
        # Só aplica fasttrack para pacientes (source != "doctor")
        if source != "doctor" and (source == "app" or source == "whatsapp"):
            if query_clean in saudacoes:
                logger.info(f"[FastTrack] Saudação detectada: {query_clean}")
                from app.services.standard_messages import get_welcome_message_without_doctor
                return get_welcome_message_without_doctor()
            
            if query_clean == "consulta" or query_clean == "consultas":
                return "Você gostaria de ver seus agendamentos or marcar uma nova consulta? ✨"
            
        conversation_manager.update_activity(wa_from)
        config = {"configurable": {"thread_id": wa_from, "db": db}, "recursion_limit": 15}
        inputs = {
            "messages": [HumanMessage(content=query)], 
            "wa_from": wa_from,
            "user_role": source,
            "user_name": user_name,
            "user_id": user_id,
            "patient_id": patient_id
        }
        try:
            final_state = await self.app.ainvoke(inputs, config=config)
        except Exception as e:
            logger.error(f"ERRO CRÍTICO NO RAG FLOW: {e}", exc_info=True)
            return "Sabe o que é? Tive um probleminha técnico aqui. 😅 Pode tentar perguntar de novo em um instante? ✨"
        
        for msg in reversed(final_state["messages"]):
            if isinstance(msg, AIMessage) and msg.content:
                return msg.content + get_footer_message()
        return "Desculpe, não consegui processar. ✨"

    def clear_conversation(self, wa_from: str):
        conversation_manager.clear_state(wa_from)
        try: self.memory.delete_thread(wa_from)
        except: pass

    def get_conversation_state(self, wa_from: str) -> dict:
        return conversation_manager.get_state(wa_from)

    def search_only(self, query: str, doctor_id: Optional[int] = None, top_k: int = 5) -> List[Dict[str, Any]]:
        from app.services.agent_tools import _get_chroma_client
        chroma_client = _get_chroma_client()
        collection_name = f"faq_doctor_{doctor_id}" if doctor_id else "faq_doctor_0"
        
        try:
            collection = chroma_client.get_collection(collection_name)
        except Exception:
            try:
                collection = chroma_client.get_collection("faq_doctor_0")
            except Exception:
                return []
                
        if collection.count() == 0:
            return []
            
        results = collection.query(
            query_texts=[query],
            n_results=min(top_k, collection.count())
        )
        
        formatted = []
        if results and results.get("documents") and results["documents"][0]:
            for i, doc in enumerate(results["documents"][0]):
                source = results["metadatas"][0][i].get("source", "FAQ") if results.get("metadatas") else "FAQ"
                formatted.append({
                    "content": doc,
                    "source": source,
                    "scope": collection_name,
                    "distance": results["distances"][0][i] if "distances" in results and results["distances"] else None
                })
        return formatted

rag_service = RAGService()
