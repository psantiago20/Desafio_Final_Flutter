"""
rag_service.py — LangChain + LangGraph + LangSmith | Motor: Groq (primário) → NVIDIA (fallback)
"""

import os
import json
import logging
import asyncio
from typing import Annotated, List, Dict, Optional, TypedDict, Any, Sequence

# LangChain, NVIDIA & Groq
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_groq import ChatGroq
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage, ToolMessage
from langchain_core.tools import tool
from langchain_chroma import Chroma
from langchain_nvidia_ai_endpoints import NVIDIAEmbeddings

# LangGraph
from langgraph.graph import StateGraph, END, START
from langgraph.prebuilt import ToolNode
from langgraph.checkpoint.memory import MemorySaver
from langchain_core.runnables import RunnableConfig

# LangSmith
from langsmith import Client

try:
    from langchain_community.cache import SQLiteCache
    import langchain_community
    # Configurar cache semântico local (sem necessidade de Redis ou infra paga)
    # Evita re-invocar a LLM para perguntas idênticas recentes
    langchain_community.llm_cache = SQLiteCache(database_path=".langchain_cache.db")
except Exception:
    pass  # Cache é opcional — sistema funciona normalmente sem ele

from app.core.config import settings
from app.services.agent_tools import execute_tool, TOOLS_DEFINITIONS
from app.services.conversation_state import conversation_manager, validate_cpf, looks_like_cpf
from app.services.standard_messages import (
    get_welcome_message, get_welcome_message_without_doctor,
    get_cpf_request_message, get_cpf_invalid_message,
    get_cpf_confirmed_message, get_cpf_not_found_message,
    detect_cpf_required_intent, get_footer_message, get_menu_message,
    get_help_duvidas_message, get_help_exames_message
)

logger = logging.getLogger(__name__)
# Debug log to file
fh = logging.FileHandler("backend_debug.log")
fh.setLevel(logging.INFO)
fh.setFormatter(logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s"))
logger.addHandler(fh)

# Configuração LangSmith
if settings.LANGSMITH_API_KEY:
    os.environ["LANGSMITH_API_KEY"] = settings.LANGSMITH_API_KEY
    os.environ["LANGSMITH_TRACING"] = str(settings.LANGSMITH_TRACING).lower()
    os.environ["LANGSMITH_PROJECT"] = settings.LANGSMITH_PROJECT

CHROMA_PERSIST_DIR = os.environ.get(
    "CHROMA_DIR",
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data")
)

from langgraph.graph.message import add_messages

# --- DEFINIÇÃO DO ESTADO DO GRAFO ---

class AgentState(TypedDict):
    messages: Annotated[Sequence[BaseMessage], add_messages]
    wa_from: str
    wa_to: str
    doctor_info: Optional[dict]
    next_node: str # Controle de fluxo
    loop_count: int  # Contador de chamadas de ferramenta no turno atual

# --- TOOLS LANGCHAIN ---

@tool
def buscar_faq_tool(pergunta: str):
    """Busca informações técnicas, preparo de exames e convênios na base de conhecimento (PDFs/FAQs)."""
    # Esta tool será chamada pelo LangGraph
    # Implementação simplificada chamando a lógica existente
    from app.services.agent_tools import buscar_faq
    return buscar_faq(pergunta=pergunta)

@tool
def buscar_medico_tool(nome: str = None, crm: str = None, especialidade: str = None):
    """Busca dados de médicos da clínica. 
    SE o paciente perguntar quais médicos trabalham ou pedir a lista de médicos, USE ESTA FERRAMENTA SEM ARGUMENTOS UMA ÚNICA VEZ.
    NÃO chame esta ferramenta repetidas vezes tentando adivinhar parâmetros. 
    Se você já chamou buscar_medico, use o resultado e não chame novamente.
    IMPORTANTE: O campo 'especialidade' deve ser APENAS o nome da especialidade (ex: Cardiologia)."""
    from app.services.agent_tools import buscar_medico
    return buscar_medico(nome=nome, crm=crm, especialidade=especialidade)

@tool
def buscar_horarios_tool(medico_id: int):
    """Consulta a agenda de horários disponíveis de um médico. Se não souber o ID do médico, use buscar_medico para encontrá-lo antes."""
    from app.services.agent_tools import buscar_horarios
    return buscar_horarios(medico_id=medico_id)

@tool
def buscar_agendamentos_tool(cpf: str):
    """Lista todos os agendamentos vinculados a um CPF de paciente."""
    from app.services.agent_tools import buscar_agendamentos
    return buscar_agendamentos(cpf=cpf)

@tool
def listar_especialidades_tool():
    """Retorna a lista de todas as especialidades médicas atendidas na clínica."""
    from app.services.agent_tools import listar_especialidades
    # Aqui precisamos do DB, mas como o @tool do LangChain não passa o config automaticamente,
    # o _tools_node cuidará de chamar a implementação correta com o DB.
    return "Listando especialidades..."

# Mapeamento para o ToolNode
langchain_tools = [buscar_faq_tool, buscar_medico_tool, buscar_horarios_tool, buscar_agendamentos_tool, listar_especialidades_tool]

# --- RAG SERVICE CLASS ---

class RAGService:
    def __init__(self):
        # ESTRATÉGIA DE LATÊNCIA (3 camadas, todas gratuitas):
        # 1. Groq  llama-3.1-8b-instant  → ~0.5-2s  (hardware LPU, FREE em console.groq.com)
        # 2. NVIDIA llama-3.1-8b-instruct → ~5-15s  (fallback se Groq falhar)
        # 3. NVIDIA llama-3.1-70b-instruct→ ~15-30s (fallback se 8B NVIDIA falhar)

        groq_llm = None
        if settings.GROQ_API_KEY:
            groq_llm = ChatGroq(
                model="llama-3.1-8b-instant",
                api_key=settings.GROQ_API_KEY,
                temperature=0.1,
                max_tokens=350,
                timeout=5,
                max_retries=0,
            ).bind_tools(langchain_tools)

        nvidia_8b = ChatNVIDIA(
            model="meta/llama-3.1-8b-instruct",
            nvidia_api_key=settings.NVIDIA_API_KEY,
            temperature=0.1,
            max_tokens=300,
            timeout=7,
            max_retries=0
        ).bind_tools(langchain_tools)

        nvidia_70b = ChatNVIDIA(
            model="meta/llama-3.1-70b-instruct",
            nvidia_api_key=settings.NVIDIA_API_KEY,
            temperature=0.1,
            max_tokens=350,
            timeout=5,
            max_retries=0
        ).bind_tools(langchain_tools)

        # Monta cadeia de fallback de acordo com as chaves disponíveis
        if groq_llm:
            logger.info("[RAGService] Motor: Groq (primário) -> NVIDIA 8B -> NVIDIA 70B")
            self.llm = groq_llm.with_fallbacks([nvidia_8b, nvidia_70b])
            # LLM base ultra-rápida: Timeout de 5s para garantir fluidez
            self.llm_base = ChatGroq(model="llama-3.1-8b-instant", api_key=settings.GROQ_API_KEY, temperature=0.1, max_tokens=350, timeout=5, max_retries=0).with_fallbacks([
                ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1, max_tokens=300, timeout=8, max_retries=0)
            ])
        else:
            logger.warning("[RAGService] GROQ_API_KEY não configurada. Usando NVIDIA 8B como primário (latência alta).")
            self.llm = nvidia_8b.with_fallbacks([nvidia_70b])
            self.llm_base = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY, temperature=0.1, max_tokens=300, timeout=20)

        self._setup_graph()
        self.memory = MemorySaver()
        self.app = self.graph.compile(checkpointer=self.memory)

    def _setup_graph(self):
        workflow = StateGraph(AgentState)

        # Nodes
        workflow.add_node("triage", self._triage_node)
        workflow.add_node("agent", self._agent_node)
        workflow.add_node("tools", self._tools_node)
        workflow.add_node("force_search", self._force_search_node)
        workflow.add_node("welcome", self._welcome_node)
        workflow.add_node("cpf_flow", self._cpf_node)

        # Edges
        workflow.add_edge(START, "triage")
        workflow.add_edge("force_search", "agent")
        
        # Triage decide o próximo passo
        workflow.add_conditional_edges(
            "triage",
            self._triage_router,
            {
                "welcome": "welcome",
                "cpf_flow": "cpf_flow",
                "agent": "agent",
                "force_search": "force_search",
                "menu": END
            }
        )

        workflow.add_edge("welcome", END)
        workflow.add_edge("cpf_flow", END)

        # Loop de Agente e Tools
        workflow.add_conditional_edges(
            "agent",
            self._agent_router,
            {
                "continue": "tools",
                "end": END
            }
        )
        workflow.add_edge("tools", "agent")

        self.graph = workflow

    # --- NODES & ROUTERS ---

    def _triage_node(self, state: AgentState):
        """Identifica se é boas-vindas, menu ou se precisa de CPF."""
        query = state["messages"][-1].content.strip().lower()
        wa_from = state["wa_from"]

        logger.info(f"[Triage] Query: {query} de {wa_from}")
        
        # Resetar contador de loops para o novo turno
        state["loop_count"] = 0

        # 1. Interceptações de menu (0, 1, 5, X) - Prioridade total
        if query == "0": return {"next_node": "menu"}
        if query in ("x", "sair"): return {"next_node": "menu"}

        # 2. Verificar se a operação requer CPF (prioridade sobre boas-vindas)
        if conversation_manager.is_awaiting_cpf(wa_from):
            return {"next_node": "cpf_flow"}
            
        operacao = detect_cpf_required_intent(query)
        if operacao and not conversation_manager.get_cpf(wa_from):
            conversation_manager.set_awaiting_cpf(wa_from, operacao, query)
            return {"next_node": "cpf_flow"}

        # 3. Boas-vindas ou Inatividade
        if conversation_manager.is_first_or_inactive(wa_from):
            # Interceptar saudações iniciais
            if query in ("oi", "olá", "bom dia", "boa tarde", "boa noite", "oie"):
                return {"next_node": "welcome"}
        
        # Respostas curtas de cortesia (bem, tudo bem, ok, obrigado)
        # Devem ir para o agente para que ele reconheça o diálogo sem repetir o Welcome.
        cortesias = ("bem", "tudo bem", "obrigado", "obrigada", "vlw", "ok", "entendi")
        if query in cortesias:
            return {"next_node": "agent"}

        # 4. FORÇAR BUSCA AUTÔNOMA (Bypass de IA para evitar procrastinação)
        keywords_busca = ['médico', 'medico', 'doutor', 'dra', 'dr', 'especialista']
        if any(k in query for k in keywords_busca):
            logger.info("[Triage] Gatilho de Médicos detectado. Encaminhando para Busca Autônoma.")
            # Injetar instrução invisível para o Agente formatar o resultado que virá do nó de tools
            state["messages"].append(SystemMessage(content="O usuário quer a lista de médicos. O sistema já está buscando os dados. Sua tarefa será apenas formatar o resultado que receberá a seguir."))
            return {"next_node": "force_search", "messages": state["messages"]}

        return {"next_node": "agent"}

    def _triage_router(self, state: AgentState):
        node = state.get("next_node")
        if node in ("welcome", "cpf_flow", "agent", "force_search"):
            return node
        return "menu"

    def _welcome_node(self, state: AgentState):
        wa_from = state["wa_from"]
        doc_info = state["doctor_info"]
        
        conversation_manager.update_activity(wa_from)
        conversation_manager.mark_welcome_sent(wa_from)

        if doc_info:
            msg = get_welcome_message(doc_info["nome"], doc_info.get("cidade"))
        else:
            msg = get_welcome_message_without_doctor()
        
        return {"messages": [AIMessage(content=msg)]}

    def _cpf_node(self, state: AgentState, config: RunnableConfig = None):
        query = state["messages"][-1].content
        wa_from = state["wa_from"]
        db = config["configurable"].get("db")
        
        if not db:
            logger.error("[CPF Flow] Erro: DB session não encontrada no config.")
            return {"messages": [AIMessage(content="Desculpe, tive um problema técnico interno. Tente novamente mais tarde.")]}
        
        logger.info(f"[CPF Flow] Processando: {query}")

        if conversation_manager.is_awaiting_cpf(wa_from):
            # Processar resposta do CPF
            if looks_like_cpf(query):
                cpf_val = validate_cpf(query)
                if cpf_val:
                    # Buscar paciente
                    from app.models.patient import Patient
                    patient = db.query(Patient).filter(Patient.cpf == cpf_val).first()
                    if patient:
                        conversation_manager.set_cpf(wa_from, cpf_val)
                        op = conversation_manager.get_pending_operation(wa_from)
                        conversation_manager.clear_cpf_flow(wa_from)
                        return {"messages": [AIMessage(content=get_cpf_confirmed_message(patient.name, op))]}
                    return {"messages": [AIMessage(content=get_cpf_not_found_message())]}
            return {"messages": [AIMessage(content=get_cpf_invalid_message())]}
        
        # Iniciar pedido de CPF
        op = detect_cpf_required_intent(query)
        return {"messages": [AIMessage(content=get_cpf_request_message(op))]}

    async def _agent_node(self, state: AgentState, config: RunnableConfig = None):
        doc = state["doctor_info"]
        all_messages = state["messages"]

        # Detectar se é a 2ª chamada (pós-tool) — usar prompt compacto
        # Reduz drásticamente os tokens de entrada na chamada mais cara
        last_is_tool = any(isinstance(m, ToolMessage) for m in all_messages[-3:])

        if last_is_tool:
            sys_prompt = (
                "Você é a Isis, a assistente virtual super doce e prestativa da clínica. "
                "Responda apenas sobre saúde e serviços da clínica. "
                "Com base nos dados da ferramenta acima, responda ao paciente de forma muito amigável, "
                "empática e concisa. Use uma linguagem natural, como se estivesse no WhatsApp. "
                "Seja breve e use emojis carinhosos. ✨"
            )
        else:
            sys_prompt = (
                "Você é a Isis, assistente virtual da clínica, reconhecida por ser DOCE, PROATIVA e EXTREMAMENTE PRECISA. ✨\n\n"
                "DIRETRIZES SUPREMAS (ORDEM DE PRIORIDADE):\n"
                "1. BANCO DE DADOS COMO ÚNICA FONTE: Você está PROIBIDA de inventar datas, horários, valores ou qualquer informação que não venha diretamente das ferramentas. Se a ferramenta 'buscar_horarios' retornar uma lista de datas, use EXATAMENTE aquelas. Nunca deduza dias da semana ou horários por conta própria.\n"
                "2. PROTOCOLO DE BUSCA OBRIGATÓRIO: Se o usuário mencionar 'médicos', 'horários' ou 'valores', chame 'buscar_medico' ou 'buscar_horarios' IMEDIATAMENTE. \n"
                "3. PRIORIDADE DO MÉDICO ATUAL: Se o paciente já estiver visualizando informações de um médico, mantenha o foco nele.\n"
                "4. PROIBIÇÃO DE LINGUAGEM TÉCNICA: NUNCA use palavras como 'ferramentas' ou 'sistema'.\n"
                "5. RESPOSTA HUMANA (OBJETIVIDADE): Use uma linguagem natural de WhatsApp, curta e com emojis carinhosos. ✨\n\n"
                "FERRAMENTAS (INVISÍVEIS):\n"
                "- buscar_faq: Dúvidas gerais (endereço, convênios).\n"
                "- buscar_medico: Info sobre médicos.\n"
                "- listar_especialidades: O que a clínica atende.\n"
                "- buscar_horarios: Retorna a lista REAL de slots disponíveis. APRESENTE A LISTA EXATA QUE RECEBER.\n"
                "- buscar_agendamentos: Ver consultas (requer CPF)."
            )
            if doc:
                sys_prompt += f"\n\n[INFO] Médico de referência do consultório: {doc['nome']} ({doc['especialidade']})."

        # Janela deslizante filtrada: ignora mensagens de erro técnico para evitar apologias da IA
        technical_terms = ["lentidão na conexão", "problema técnico", "tente novamente", "Desculpe pelo erro"]
        raw_window = []
        for msg in all_messages[-12:]:
            if isinstance(msg, AIMessage) and any(term in msg.content for term in technical_terms):
                continue
            raw_window.append(msg)
        
        raw_window = raw_window[-10:]
        
        # Algoritmo de Validação Absoluta de Contexto (Evita Erro 400 Bad Request)
        # OpenAI/Groq exigem que AIMessage(tool_calls) e ToolMessage ocorram sempre em pares.
        valid_window = []
        i = 0
        while i < len(raw_window):
            msg = raw_window[i]
            if isinstance(msg, AIMessage) and getattr(msg, "tool_calls", None):
                # Se for AIMessage com tool_calls, verifica se o próximo é o ToolMessage correspondente
                if i + 1 < len(raw_window) and isinstance(raw_window[i+1], ToolMessage):
                    valid_window.append(msg)
                    valid_window.append(raw_window[i+1])
                    i += 2
                else:
                    # AIMessage com tool_calls órfão (ex: loop interrompido no turno anterior), descartar
                    i += 1
            elif isinstance(msg, ToolMessage):
                # ToolMessage órfão (AIMessage ficou de fora da janela), descartar
                i += 1
            else:
                # Mensagens normais (HumanMessage, AIMessage de texto puro, etc)
                valid_window.append(msg)
                i += 1
                
        messages = [SystemMessage(content=sys_prompt)] + valid_window

        try:
            logger.info(f"[Agent] Chamando LLM (post_tool={last_is_tool}, msgs={len(messages)})...")
            # Se já executamos a tool, usamos a LLM base (sem tools) para forçar uma resposta em texto
            llm_to_use = self.llm_base if last_is_tool else self.llm
            # TIMEOUT AGRESSIVO: 20s para resposta total ou erro.
            response = await asyncio.wait_for(llm_to_use.ainvoke(messages), timeout=20)
            return {"messages": [response]}
        except asyncio.TimeoutError:
            logger.error("[Agent] Timeout agressivo atingido (20s). Abortando.")
            return {"messages": [AIMessage(content="Estou com uma pequena lentidão na conexão, mas não esqueci de você! ✨ Poderia repetir sua última dúvida rapidinho?")]}
        except Exception as e:
            logger.error(f"[Agent] Erro na LLM: {e}")
            return {"messages": [AIMessage(content="Tive um probleminha técnico rápido. Vamos tentar de novo? 😊")]}

    def _force_search_node(self, state: AgentState, config: RunnableConfig = None):
        """Força a execução da ferramenta de médicos sem passar pela decisão da LLM."""
        logger.info("[Force Search] Executando busca de médicos obrigatória.")
        db = None
        if config and "configurable" in config:
            db = config["configurable"].get("db")
            
        if not db:
            return {"messages": [AIMessage(content="Erro técnico: Banco de dados indisponível.")]}
            
        # Executar a ferramenta buscar_medico manualmente
        result = execute_tool("buscar_medico", {}, db)
        
        # Criar uma ToolMessage fake e uma AIMessage fake para manter a coerência do histórico
        import uuid
        tool_call_id = f"force_{uuid.uuid4().hex[:8]}"
        
        # 1. AI Message simulando que ela chamou a tool
        ai_msg = AIMessage(
            content="",
            tool_calls=[{
                "name": "buscar_medico",
                "args": {},
                "id": tool_call_id
            }]
        )
        
        # 2. Tool Message com o resultado real do banco
        tool_msg = ToolMessage(
            tool_call_id=tool_call_id,
            content=result
        )
        
        # Adicionar ambas ao estado
        return {"messages": [ai_msg, tool_msg]}

    def _tools_node(self, state: AgentState, config: RunnableConfig = None):
        """Executa as ferramentas mapeando-as para o banco de dados."""
        last_message = state["messages"][-1]
        tool_results = []

        # Forçar apenas 1 tool call por vez para evitar que a LLM estoure a API
        if hasattr(last_message, "tool_calls") and len(last_message.tool_calls) > 1:
            logger.warning("[Tools Node] LLM tentou chamar múltiplas tools. Limitando a 1.")
            last_message.tool_calls = [last_message.tool_calls[0]]

        db = None
        if config and "configurable" in config:
            db = config["configurable"].get("db")

        if not db:
            logger.error("[Tools Node] Database session not found in config.")
            for tool_call in last_message.tool_calls:
                tool_results.append(ToolMessage(
                    tool_call_id=tool_call["id"],
                    content="Erro técnico: Banco de dados não disponível para esta operação."
                ))
            return {"messages": tool_results}

        for tool_call in last_message.tool_calls:
            tool_name = tool_call["name"]
            arguments = tool_call["args"]
            clean_name = tool_name.replace("_tool", "")

            logger.info(f"[Tools] Executando: {clean_name}({arguments})")
            result = execute_tool(clean_name, arguments, db)

            # Truncar resultado a 800 chars — evita sobrecarregar o contexto da LLM
            # A LLM não precisa de texto infinito para formatar a resposta
            MAX_TOOL_CHARS = 800
            if isinstance(result, str) and len(result) > MAX_TOOL_CHARS:
                result = result[:MAX_TOOL_CHARS] + "\n[... resultado truncado para otimização de latência]"
                logger.info(f"[Tools] Resultado truncado a {MAX_TOOL_CHARS} chars.")

            tool_results.append(ToolMessage(
                tool_call_id=tool_call["id"],
                content=result
            ))

        return {"messages": tool_results}

    def _agent_router(self, state: AgentState):
        last_msg = state["messages"][-1]
        
        # Incrementar loop_count se houve tool_calls
        if hasattr(last_msg, "tool_calls") and last_msg.tool_calls:
            state["loop_count"] = state.get("loop_count", 0) + 1
            
            # Limite rigoroso de 1 rodada de ferramenta por turno de usuário
            if state["loop_count"] > 1:
                logger.warning(f"[AgentRouter] Interrompendo loop de Tool Calls. Limite atingido ({state['loop_count']}).")
                return "end"
            return "continue"
            
        return "end"

    # --- MÉTODO PÚBLICO ---

    async def get_rag_response(
        self,
        query: str,
        wa_to: Optional[str],
        db,
        top_k: int = 5,
        wa_from: str = None,
        source: str = "whatsapp"
    ) -> str:
        import time
        start_time = time.time()
        
        if not wa_from: wa_from = "anonymous"

        # 1. Buscar info do médico
        doc_info = self._get_doctor_info_by_phone(wa_to, db) if wa_to else None
        
        # 2. OTIMIZAÇÃO: Resposta ultrarrápida para saudações no App
        import re
        query_clean = re.sub(r'[^\w\s]', '', query.lower()).strip()
        greetings = ["oi", "ola", "olá", "bom dia", "boa tarde", "boa noite", "oie"]
        if source == "app" and query_clean in greetings:
            self.clear_conversation(wa_from)  # Limpa o histórico preso (como loops anteriores)
            conversation_manager.update_activity(wa_from)
            conversation_manager.mark_welcome_sent(wa_from)
            logger.info(f"[FastTrack] Saudação detectada no App. Tempo: {time.time() - start_time:.3f}s")
            return "Olá! Tudo bem? ✨ Como posso te ajudar hoje? 😊"

        # Config do thread para persistência do LangGraph e rastreio do LangSmith
        env_tag = "env:prod" if getattr(settings, "ENV", "dev") == "prod" else "env:dev"
        config = {
            "tags": [env_tag, f"source:{source}"],
            "configurable": {"thread_id": wa_from, "db": db, "source": source},
            "recursion_limit": 5
        }
        
        # Se for a primeira mensagem vinda do APP e não for saudação (já tratada acima),
        # pulamos o welcome para processar a dúvida.
        if source == "app" and conversation_manager.is_first_or_inactive(wa_from):
            conversation_manager.update_activity(wa_from)
            conversation_manager.mark_welcome_sent(wa_from)

        # Executar grafo
        inputs = {
            "messages": [HumanMessage(content=query)],
            "wa_from": wa_from,
            "doctor_info": doc_info
        }
        
        logger.info(f"[RAG] Iniciando execução do grafo para {wa_from}...")
        graph_start = time.time()
        final_state = await self.app.ainvoke(inputs, config=config)
        logger.info(f"[RAG] Grafo concluído em {time.time() - graph_start:.3f}s")
        
        # Procurar a resposta final no estado resultante (Apenas mensagens deste turno)
        response_text = None
        for msg in reversed(final_state["messages"]):
            if isinstance(msg, HumanMessage):
                break # Chegamos na pergunta do usuário, não há resposta nova à frente
            if isinstance(msg, AIMessage) and msg.content:
                response_text = msg.content
                break
        
        if response_text:
            total_time = time.time() - start_time
            logger.info(f"[RAG] Resposta final gerada em {total_time:.3f}s")
            return response_text + get_footer_message()

        return "Desculpe, não consegui processar sua solicitação no momento. ✨"

    def _get_doctor_info_by_phone(self, wa_to: str, db) -> dict:
        """Portado da versão anterior."""
        try:
            from app.models.medico import Medico
            medico = db.query(Medico).filter(Medico.whatsapp == wa_to, Medico.ativo == True).first()
            if medico:
                return {
                    "id": medico.id, "nome": medico.nome_completo,
                    "endereco": medico.endereco, "especialidade": medico.especialidade,
                    "convenios": medico.convenios
                }
        except: pass
        return None

    def search_only(self, query: str, doctor_id: Optional[int] = None, top_k: int = 5) -> List[Dict[str, Any]]:
        """
        Busca semântica pura no ChromaDB sem envolver a LLM.
        Utilizado para testes de recuperação e estatísticas.
        """
        print(f"[DEBUG] Executando search_only para query: {query}")
        from app.services.agent_tools import _get_chroma_client
        chroma_client = _get_chroma_client()
        
        # Tenta a coleção específica do médico, ou cai para a global (0)
        collection_name = f"faq_doctor_{doctor_id}" if doctor_id else "faq_doctor_0"
        
        try:
            collection = chroma_client.get_collection(collection_name)
        except Exception:
            try:
                collection = chroma_client.get_collection("faq_doctor_0")
            except Exception:
                logger.warning(f"Coleção {collection_name} não encontrada e fallback falhou.")
                return []

        if collection.count() == 0:
            return []

        try:
            results = collection.query(
                query_texts=[query],
                n_results=min(top_k, collection.count())
            )
            
            structured_results = []
            if results and results["documents"] and results["documents"][0]:
                for i, doc in enumerate(results["documents"][0]):
                    meta = results["metadatas"][0][i] if results["metadatas"] else {}
                    dist = results["distances"][0][i] if results["distances"] else None
                    
                    structured_results.append({
                        "content": doc,
                        "source": meta.get("source", "FAQ"),
                        "scope": "doctor" if doctor_id else "global",
                        "distance": dist
                    })
            return structured_results
        except Exception as e:
            logger.error(f"Erro na execução de search_only: {e}")
            return []

    def clear_conversation(self, wa_from: str):
        conversation_manager.clear_state(wa_from)

    def get_conversation_state(self, wa_from: str) -> dict:
        return conversation_manager.get_state(wa_from)

# Singleton
rag_service = RAGService()

