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
def buscar_horarios_tool(medico_id: int):
    """Agenda de horários disponíveis."""
    from app.services.agent_tools import buscar_horarios
    return buscar_horarios(medico_id=medico_id)

langchain_tools = [buscar_faq_tool, buscar_medico_tool, buscar_horarios_tool]

class RAGService:
    def __init__(self):
        # Configuração de Modelos (Groq como primário)
        if settings.GROQ_API_KEY:
            self.llm = ChatGroq(model="llama-3.1-8b-instant", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=400).bind_tools(langchain_tools)
            self.llm_base = ChatGroq(model="llama-3.1-8b-instant", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=400)
        else:
            self.llm = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1).bind_tools(langchain_tools)
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

    def _triage_node(self, state: AgentState):
        query = state["messages"][-1].content.strip().lower()
        wa_from = state["wa_from"]
        state["loop_count"] = 0

        # Persistência de Contexto
        if "marina" in query:
            state["active_doctor_id"], state["active_doctor_name"] = 1, "Dra. Marina Costa"
        elif "thorne" in query:
            state["active_doctor_id"], state["active_doctor_name"] = 2, "Dr. Thorne Blackwood"
        
        if any(k in query for k in ["valor", "preço"]): state["last_search_type"] = "valor"
        elif any(k in query for k in ["parcela", "pagamento"]): state["last_search_type"] = "pagamento"
        elif any(k in query for k in ["convênio", "aceita"]): state["last_search_type"] = "convênio"

        if query in ("0", "x", "sair"): return {"next_node": "menu"}
        if conversation_manager.is_awaiting_cpf(wa_from): return {"next_node": "cpf_flow"}
        
        if any(k in query for k in ['médico', 'medico', 'doutor', 'dra', 'dr', 'datas', 'horários', 'valor', 'parcela', 'convênio']):
            return {"next_node": "force_search"}
        return {"next_node": "agent"}

    def _triage_router(self, state: AgentState):
        return state.get("next_node", "agent")

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
            return {"messages": [AIMessage(content=get_cpf_invalid_message())]}
        return {"messages": [AIMessage(content=get_cpf_request_message("atendimento"))]}

    async def _agent_node(self, state: AgentState, config: RunnableConfig = None):
        all_messages = state["messages"]
        last_is_tool = len(all_messages) > 0 and isinstance(all_messages[-1], ToolMessage)

        # AGGREGAÇÃO DE FERRAMENTAS (Limpa e Humana)
        if last_is_tool:
            tool_results = []
            seen_contents = set()
            for msg in reversed(all_messages):
                if isinstance(msg, HumanMessage): break
                if isinstance(msg, ToolMessage) and msg.content not in seen_contents:
                    # Limpeza de strings técnicas na resposta final
                    clean_res = msg.content.replace("[Fonte: FAQ]", "").replace("[Fonte: Clínica]", "").strip()
                    tool_results.insert(0, clean_res)
                    seen_contents.add(msg.content)
            
            if tool_results:
                return {"messages": [AIMessage(content="\n\n".join(tool_results))]}

        # Prompt da Isis (Persona Estrita da Clínica)
        sys_prompt = (
            "Você é a Isis, assistente virtual doce e prestativa da clínica. ✨\n"
            "REGRA DE OURO: Você SÓ fala sobre assuntos da clínica (médicos, horários, exames, convênios e saúde).\n"
            "Se o usuário perguntar sobre QUALQUER outro assunto (esportes, política, notícias, etc), negue educadamente e diga que você está aqui apenas para ajudar com os atendimentos da clínica.\n"
            "Responda sempre baseada nos dados das ferramentas. Se não houver dados, peça para falar com a recepção. ✨"
        )
        active_doc = state.get("active_doctor_name")
        context = f"\n[Contexto: Médico {active_doc or 'Geral'}]"
        messages = [SystemMessage(content=sys_prompt + context)] + all_messages[-6:]

        try:
            response = await asyncio.wait_for(self.llm.ainvoke(messages), timeout=25)
            content = response.content
            if any(k in content.lower() for k in ["localhost", "11434", "ollama", "aula", ".pdf"]):
                return {"messages": [AIMessage(content="Sabe o que é? Não localizei essa info exata agora. 😅 Por favor, fale com nossa recepção! ✨")]}
            return {"messages": [response]}
        except:
            return {"messages": [AIMessage(content="Sabe o que é? Não consegui localizar agora. 😅 Por favor, fale com nossa recepção! ✨")]}

    def _force_search_node(self, state: AgentState, config: RunnableConfig = None):
        """Busca automática com separação rígida de intenções."""
        query = state["messages"][-1].content.lower()
        db = config["configurable"].get("db")
        target_id = state.get("active_doctor_id")

        # 1. VALOR / PREÇO (Prioridade: Banco de Médicos)
        if any(k in query for k in ["valor", "preço", "quanto", "custo"]):
            logger.info("[Force Search] Intenção de VALOR detectada.")
            res = execute_tool("buscar_medico", {"nome": state.get("active_doctor_name")} if target_id else {}, db)
            tid = f"v_{uuid.uuid4().hex[:4]}"
            return {"messages": [AIMessage(content="", tool_calls=[{"name":"v","args":{},"id":tid}]), ToolMessage(tool_call_id=tid, content=res, name="v")]}

        # 2. PARCELAMENTO / PAGAMENTO / CONVÊNIO
        if any(k in query for k in ["parcela", "pagamento", "pix", "cartão", "convênio", "convenio"]):
            logger.info("[Force Search] Intenção FINANCEIRA/CONVÊNIO detectada.")
            
            # Se a dúvida for sobre CONVÊNIOS, buscamos nos MÉDICOS primeiro (onde estão os dados reais)
            if "convênio" in query or "convenio" in query:
                res_medicos = execute_tool("buscar_medico", {}, db)
                res_faq = execute_tool("buscar_faq", {"pergunta": "Quais os convênios aceitos?"}, db)
                
                # Agregamos os dois para uma resposta completa
                tid_m, tid_f = f"m_{uuid.uuid4().hex[:4]}", f"f_{uuid.uuid4().hex[:4]}"
                return {
                    "messages": [
                        AIMessage(content="", tool_calls=[{"name":"m","args":{},"id":tid_m}, {"name":"f","args":{},"id":tid_f}]),
                        ToolMessage(tool_call_id=tid_m, content=res_medicos, name="m"),
                        ToolMessage(tool_call_id=tid_f, content=res_faq, name="f")
                    ]
                }

            # Se for apenas parcelamento
            pergunta = "Formas de pagamento e parcelamento?" if "parcela" in query else "Formas de pagamento?"
            res = execute_tool("buscar_faq", {"pergunta": pergunta}, db)
            if not res or "Nenhuma informação" in res or len(res) < 15:
                return {"messages": [AIMessage(content="Não tenho os detalhes de parcelamento aqui. 😅 Por favor, fale com nossa recepção! ✨")]}
            tid = f"f_{uuid.uuid4().hex[:4]}"
            return {"messages": [AIMessage(content="", tool_calls=[{"name":"f","args":{},"id":tid}]), ToolMessage(tool_call_id=tid, content=res, name="f")]}

        # 3. DATAS / HORÁRIOS
        if any(k in query for k in ["datas", "horários", "horario", "os dois", "ambos"]):
            if not target_id or any(k in query for k in ["os dois", "ambos"]):
                r1 = execute_tool("buscar_horarios", {"medico_id": 1}, db)
                r2 = execute_tool("buscar_horarios", {"medico_id": 2}, db)
                c1, c2 = f"c1_{uuid.uuid4().hex[:4]}", f"c2_{uuid.uuid4().hex[:4]}"
                return {"messages": [AIMessage(content="", tool_calls=[{"name":"b1","args":{},"id":c1},{"name":"b2","args":{},"id":c2}]), ToolMessage(tool_call_id=c1, content=r1, name="b1"), ToolMessage(tool_call_id=c2, content=r2, name="b2")]}
            res = execute_tool("buscar_horarios", {"medico_id": target_id}, db)
            tid = f"c_{uuid.uuid4().hex[:4]}"
            return {"messages": [AIMessage(content="", tool_calls=[{"name":"b","args":{},"id":tid}]), ToolMessage(tool_call_id=tid, content=res, name="b")]}

        # 4. MÉDICOS
        if any(k in query for k in ['médico', 'medico', 'doutor', 'dra', 'dr', 'especialista']):
            res = execute_tool("buscar_medico", {}, db)
            tid = f"m_{uuid.uuid4().hex[:4]}"
            return {"messages": [AIMessage(content="", tool_calls=[{"name":"m","args":{},"id":tid}]), ToolMessage(tool_call_id=tid, content=res, name="m")]}

        return {"messages": [AIMessage(content="Não localizei essa informação específica. 😅 Por favor, fale com nossa recepção! ✨")]}

    def _tools_node(self, state: AgentState, config: RunnableConfig = None):
        last_msg = state["messages"][-1]
        results = []
        db = config["configurable"].get("db")
        for tc in last_msg.tool_calls:
            res = execute_tool(tc["name"].replace("_tool",""), tc["args"], db)
            results.append(ToolMessage(tool_call_id=tc["id"], content=str(res)))
        return {"messages": results}

    def _agent_router(self, state: AgentState):
        last_msg = state["messages"][-1]
        if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
            state["loop_count"] = state.get("loop_count", 0) + 1
            return "continue" if state["loop_count"] <= 1 else "end"
        return "end"

    async def get_rag_response(self, query: str, wa_to: str, db, wa_from: str = "anonymous", source: str = "whatsapp") -> str:
        if query.lower() in ["reset", "limpar"]:
            self.clear_conversation(wa_from)
            return "Sessão reiniciada! ✨"
        
        conversation_manager.update_activity(wa_from)
        config = {"configurable": {"thread_id": wa_from, "db": db}, "recursion_limit": 5}
        inputs = {"messages": [HumanMessage(content=query)], "wa_from": wa_from}
        final_state = await self.app.ainvoke(inputs, config=config)
        
        for msg in reversed(final_state["messages"]):
            if isinstance(msg, AIMessage) and msg.content:
                return msg.content + get_footer_message()
        return "Desculpe, não consegui processar. ✨"

    def clear_conversation(self, wa_from: str):
        conversation_manager.clear_state(wa_from)
        try: self.memory.delete_thread(wa_from)
        except: pass

rag_service = RAGService()
