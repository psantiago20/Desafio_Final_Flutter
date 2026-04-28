"""
rag_service.py — Agente de IA com Tool Calling + Gerenciamento de Conversa

Fluxo do agente (baseado no diagrama de arquitetura):

    Paciente → É primeira interação ou inativo > 1h?
                    │ Sim                        │ Não
                    ▼                            ▼
              Boas-vindas                   Precisa de CPF?
           (nome + cidade                  (agendamento, cancelamento,
            do médico)                      consulta de agendamentos)
                                               │ Sim        │ Não
                                               ▼            ▼
                                          Pedir CPF     Agente de IA
                                               │        (Tool Calling)
                                               ▼            │
                                          Validar CPF       │
                                               │            │
                                               ▼            ▼
                                          Executar       Resposta ao
                                          operação       paciente

O agente usa Tool Calling nativo do Llama 3.1 via NVIDIA Nim para
decidir QUANDO e QUAL tool chamar baseado na pergunta do paciente.
"""

import json
import logging
import os
from typing import Optional, List, Dict

import httpx
import chromadb

from app.core.config import settings
from app.services.agent_tools import TOOLS_DEFINITIONS, execute_tool
from app.services.conversation_state import (
    conversation_manager, validate_cpf, looks_like_cpf
)
from app.services.standard_messages import (
    get_welcome_message, get_welcome_message_without_doctor,
    get_cpf_request_message, get_cpf_invalid_message,
    get_cpf_confirmed_message, get_cpf_not_found_message,
    detect_cpf_required_intent, get_help_duvidas_message,
    get_help_exames_message, get_footer_message, get_menu_message
)

logger = logging.getLogger(__name__)

CHROMA_PERSIST_DIR = os.environ.get(
    "CHROMA_DIR",
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data")
)

# Número máximo de iterações de tool calling (evitar loops infinitos)
MAX_TOOL_ITERATIONS = 3

# System prompt do agente
AGENT_SYSTEM_PROMPT = (
    "Você é o assistente virtual do OmniConnect, uma plataforma de gestão médica. "
    "Você ajuda pacientes via WhatsApp a:\n"
    "- Agendar consultas e exames\n"
    "- Tirar dúvidas sobre preparos de exames\n"
    "- Consultar horários de médicos\n"
    "- Ver e gerenciar agendamentos\n"
    "- Informar sobre convênios aceitos\n\n"
    "REGRAS:\n"
    "1. Responda SEMPRE em português brasileiro.\n"
    "2. Seja profissional, gentil e conciso.\n"
    "3. Use as ferramentas disponíveis para buscar informações ANTES de responder.\n"
    "4. Se a pergunta for GERAL (preparo de exame, convênios, etc), use 'buscar_faq'.\n"
    "5. Se a pergunta mencionar um MÉDICO específico, use 'buscar_medico'.\n"
    "6. Se a pergunta for sobre HORÁRIOS/DISPONIBILIDADE, use 'buscar_horarios'.\n"
    "7. Se o paciente quiser ver/cancelar AGENDAMENTOS, use 'buscar_agendamentos'.\n"
    "8. NUNCA invente informações. Se não encontrar, diga que não tem a informação.\n"
    "9. Formate para WhatsApp (texto simples, emojis com moderação).\n"
    "10. Você PODE chamar múltiplas ferramentas se necessário.\n"
    "11. O CPF do paciente já foi validado e está no contexto. Use-o diretamente nas ferramentas.\n"
)


class RAGService:
    """
    Agente de IA com Tool Calling que combina:
    - Gerenciamento de estado da conversa (boas-vindas, CPF)
    - Busca semântica na FAQ (ChromaDB) via tool buscar_faq
    - Busca dinâmica no banco de dados via tools buscar_medico/horarios/agendamentos
    - LLM (NVIDIA Nim / Llama 3.1) com suporte nativo a tool calling
    """

    def __init__(self):
        self.api_key = settings.NVIDIA_API_KEY
        self.base_url = "https://integrate.api.nvidia.com/v1"
        self.model = "meta/llama-3.1-8b-instruct"
        self._chroma_client = None

    @property
    def chroma_client(self) -> chromadb.ClientAPI:
        """Lazy initialization do ChromaDB client."""
        if self._chroma_client is None:
            self._chroma_client = chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)
        return self._chroma_client

    # ------------------------------------------------------------------ #
    #  BUSCA SEMÂNTICA NA FAQ (mantido para endpoints de admin)
    # ------------------------------------------------------------------ #

    def search_faq(
        self,
        query: str,
        doctor_id: Optional[int],
        top_k: int = 5
    ) -> List[Dict]:
        """Busca semântica na FAQ (ChromaDB). Usado pelos endpoints de admin."""
        collection_name = f"faq_doctor_{doctor_id}" if doctor_id else "faq_global"

        try:
            collection = self.chroma_client.get_collection(collection_name)
        except Exception:
            try:
                collection = self.chroma_client.get_collection("faq_doctor_0")
            except Exception:
                return []

        try:
            results = collection.query(
                query_texts=[query],
                n_results=min(top_k, collection.count()) if collection.count() > 0 else 1
            )
        except Exception as e:
            logger.error(f"Erro na busca semântica: {e}")
            return []

        chunks = []
        if results and results["documents"]:
            for i, doc in enumerate(results["documents"][0]):
                metadata = results["metadatas"][0][i] if results["metadatas"] else {}
                distance = results["distances"][0][i] if results.get("distances") else None
                chunks.append({
                    "content": doc,
                    "source": metadata.get("source", "unknown"),
                    "scope": metadata.get("scope", "unknown"),
                    "distance": distance
                })

        return chunks

    def search_only(self, query: str, doctor_id: Optional[int], top_k: int = 5) -> List[Dict]:
        """Busca sem LLM. Útil para debug."""
        return self.search_faq(query, doctor_id, top_k)

    # ------------------------------------------------------------------ #
    #  CHAMADA LLM COM TOOL CALLING
    # ------------------------------------------------------------------ #

    async def _call_llm_with_tools(
        self,
        messages: list,
        tools: list = None
    ) -> dict:
        """
        Chama a LLM (NVIDIA Nim) com suporte a tool calling.
        
        Returns:
            Dict com 'content' e/ou 'tool_calls'
        """
        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": self.model,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 1024
        }

        if tools:
            payload["tools"] = tools
            payload["tool_choice"] = "auto"

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=45.0)

                if response.status_code != 200:
                    logger.error(f"NVIDIA API Error ({response.status_code}): {response.text}")
                    return {"content": None, "tool_calls": None, "error": response.text}

                result = response.json()
                choice = result["choices"][0]["message"]

                return {
                    "content": choice.get("content"),
                    "tool_calls": choice.get("tool_calls"),
                    "role": choice.get("role", "assistant")
                }

            except Exception as e:
                logger.error(f"Erro ao chamar NVIDIA Nim: {e}")
                return {"content": None, "tool_calls": None, "error": str(e)}

    # ------------------------------------------------------------------ #
    #  BUSCA DE MÉDICO PARA BOAS-VINDAS
    # ------------------------------------------------------------------ #

    def _get_doctor_info_by_phone(self, wa_to: str, db) -> dict:
        """Busca dados do médico no banco usando o WhatsApp para a mensagem de boas-vindas e contexto."""
        try:
            from app.models.medico import Medico
            medico = db.query(Medico).filter(
                Medico.whatsapp == wa_to, Medico.ativo == True
            ).first()
            if medico:
                return {
                    "id": medico.id,
                    "nome": medico.nome_completo,
                    "cidade": getattr(medico, "cidade", None),
                    "especialidade": medico.especialidade,
                }
        except Exception as e:
            logger.error(f"Erro ao buscar médico para boas-vindas: {e}")
        return None

    # ------------------------------------------------------------------ #
    #  VALIDAÇÃO DE CPF E BUSCA DE PACIENTE
    # ------------------------------------------------------------------ #

    def _find_patient_by_cpf(self, cpf: str, db) -> dict:
        """Busca paciente no banco pelo CPF."""
        try:
            from app.models.patient import Patient
            cpf_limpo = "".join(c for c in cpf if c.isdigit())
            
            # Banco pode ter CPF formatado (123.456.789-00) ou apenas números
            cpf_formatado = ""
            if len(cpf_limpo) == 11:
                cpf_formatado = f"{cpf_limpo[:3]}.{cpf_limpo[3:6]}.{cpf_limpo[6:9]}-{cpf_limpo[9:]}"

            patient = db.query(Patient).filter(
                (Patient.cpf == cpf_limpo) | (Patient.cpf == cpf_formatado) | (Patient.cpf == cpf)
            ).first()
            if patient:
                return {
                    "id": patient.id,
                    "nome": patient.name,
                    "cpf": patient.cpf,
                }
        except Exception as e:
            logger.error(f"Erro ao buscar paciente por CPF: {e}")
        return None

    # ------------------------------------------------------------------ #
    #  PIPELINE PRINCIPAL (COM GERENCIAMENTO DE ESTADO)
    # ------------------------------------------------------------------ #

    async def get_rag_response(
        self,
        query: str,
        wa_to: Optional[str],
        db,
        top_k: int = 5,
        wa_from: str = None
    ) -> str:
        """
        Pipeline do Agente de IA com gerenciamento de estado de conversa.
        
        Fluxo:
        1. Verifica se é primeira interação ou inativo > 1h → boas-vindas
        2. Verifica se está aguardando CPF → valida CPF
        3. Detecta se a operação requer CPF → pede CPF
        4. Executa pipeline normal de Tool Calling
        
        Args:
            query: Mensagem do paciente
            wa_to: Número WhatsApp de destino (do médico/clínica)
            db: Sessão SQLAlchemy
            top_k: Chunks para busca FAQ
            wa_from: Número WhatsApp do paciente (para tracking de estado)
            
        Returns:
            Resposta do agente como string
        """
        # Se não tiver wa_from, gerar um identificador genérico
        if not wa_from:
            wa_from = f"anonymous_{id(query)}"

        logger.info(f"Agent Pipeline: query='{query[:80]}' wa_to={wa_to} wa_from={wa_from}")

        # Buscar dados do médico pelo wa_to
        doc_info = None
        doctor_id = None
        if wa_to:
            doc_info = self._get_doctor_info_by_phone(wa_to, db)
            if doc_info:
                doctor_id = doc_info["id"]

        # ---- PASSO 1: Verificar se é primeira interação ou inatividade ----
        if conversation_manager.is_first_or_inactive(wa_from):
            conversation_manager.update_activity(wa_from)
            conversation_manager.mark_welcome_sent(wa_from)

            # Buscar dados do médico para personalizar boas-vindas
            if doc_info:
                    welcome = get_welcome_message(
                        nome_medico=doc_info["nome"],
                        cidade=doc_info.get("cidade")
                    )
                    logger.info(f"Enviando boas-vindas para {wa_from} (médico: {doc_info['nome']})")
                    return welcome

            # Sem médico identificado → boas-vindas genérica
            welcome = get_welcome_message_without_doctor()
            logger.info(f"Enviando boas-vindas genéricas para {wa_from}")
            return welcome

        # Atualizar timestamp de atividade
        conversation_manager.update_activity(wa_from)

        # ---- PASSO 2: Verificar interceptações diretas (menu e opções) ----
        msg_lower = query.strip().lower()
        
        # Voltar ao menu principal
        if msg_lower == "0":
            conversation_manager.clear_cpf_flow(wa_from)
            return get_menu_message()
            
        # Finalizar atendimento
        if msg_lower in ("x", "❌", "finalizar", "sair"):
            conversation_manager.clear_state(wa_from)
            return "Atendimento finalizado. Qualquer dúvida, é só me chamar novamente! 👋"
            
        # Opção 1 (Dúvidas)
        if msg_lower == "1":
            return get_help_duvidas_message() + get_footer_message()
            
        # Opção 5 (Preparo de exame)
        if msg_lower == "5":
            return get_help_exames_message() + get_footer_message()

        # ---- PASSO 3: Verificar se está aguardando CPF ----
        if conversation_manager.is_awaiting_cpf(wa_from):
            return self._handle_cpf_response(query, doctor_id, db, wa_from)

        # ---- PASSO 4: Detectar se a operação requer CPF ----
        operacao = detect_cpf_required_intent(query)
        if operacao:
            # Verificar se já temos o CPF coletado nesta sessão
            cpf_existente = conversation_manager.get_cpf(wa_from)
            if cpf_existente:
                # Já temos o CPF → prosseguir normalmente com o agente
                logger.info(f"CPF já coletado para {wa_from}, prosseguindo com operação '{operacao}'")
                # Injetar CPF no query para o agente usar
                enriched_query = f"{query} (CPF do paciente: {cpf_existente})"
                response = await self._run_agent_pipeline(enriched_query, doctor_id, db, top_k)
                return response + get_footer_message()
            else:
                # Precisa coletar CPF primeiro
                conversation_manager.set_awaiting_cpf(wa_from, operacao, query)
                return get_cpf_request_message(operacao)

        # ---- PASSO 5: Pipeline normal do agente ----
        # Injetar CPF se já coletado (para que o agente possa usar em tools)
        cpf_existente = conversation_manager.get_cpf(wa_from)
        if cpf_existente:
            enriched_query = f"{query} (CPF do paciente: {cpf_existente})"
        else:
            enriched_query = query

        response = await self._run_agent_pipeline(enriched_query, doctor_id, db, top_k)
        return response + get_footer_message()

    # ------------------------------------------------------------------ #
    #  HANDLER DE RESPOSTA COM CPF
    # ------------------------------------------------------------------ #

    def _handle_cpf_response(self, text: str, doctor_id, db, wa_from: str) -> str:
        """
        Processa a resposta quando estamos aguardando o CPF do paciente.
        """
        text_stripped = text.strip().lower()

        # Verificar se quer cancelar
        if text_stripped in ("cancelar", "voltar", "sair", "não", "nao"):
            conversation_manager.clear_cpf_flow(wa_from)
            return "Ok! Operação cancelada. Como posso te ajudar? 😊"

        # Verificar se parece ser um CPF
        if looks_like_cpf(text):
            cpf_validado = validate_cpf(text)
            if cpf_validado:
                # CPF válido → buscar paciente no banco
                paciente = self._find_patient_by_cpf(cpf_validado, db)
                if paciente:
                    # Paciente encontrado!
                    conversation_manager.set_cpf(wa_from, cpf_validado)
                    operacao = conversation_manager.get_pending_operation(wa_from)
                    mensagem_original = conversation_manager.get_pending_message(wa_from)
                    conversation_manager.clear_cpf_flow(wa_from)

                    confirmed_msg = get_cpf_confirmed_message(paciente["nome"], operacao)
                    logger.info(f"CPF validado para {wa_from}: paciente={paciente['nome']}")

                    # Retornar mensagem de confirmação
                    # A próxima mensagem do paciente (ou re-execução) usará o CPF armazenado
                    return confirmed_msg
                else:
                    # CPF válido mas paciente não encontrado
                    return get_cpf_not_found_message()
            else:
                # CPF inválido (formato errado)
                return get_cpf_invalid_message()
        else:
            # Texto não parece CPF
            return get_cpf_invalid_message()

    # ------------------------------------------------------------------ #
    #  PIPELINE DO AGENTE (LOOP DE TOOL CALLING)
    # ------------------------------------------------------------------ #

    async def _run_agent_pipeline(
        self,
        query: str,
        doctor_id: Optional[int],
        db,
        top_k: int = 5
    ) -> str:
        """
        Pipeline do Agente de IA com Tool Calling (lógica core).
        
        1. Envia mensagem do paciente + definições de tools à LLM
        2. Se LLM responde com tool_calls → executa tools → envia resultados de volta
        3. Repete até LLM dar resposta final (ou atingir MAX_TOOL_ITERATIONS)
        """
        logger.info(f"Agent Pipeline Core: query='{query[:80]}' doctor_id={doctor_id}")

        if not self.api_key:
            return self._fallback_without_llm(query, doctor_id, db)

        # Montar system prompt com contexto do médico (se identificado)
        system_content = AGENT_SYSTEM_PROMPT
        if doctor_id:
            system_content += f"\n\nContexto: O paciente está conversando pelo WhatsApp do médico com ID={doctor_id}. "
            system_content += "Use este ID nas ferramentas quando necessário.\n"

        # Histórico de mensagens para o loop
        messages = [
            {"role": "system", "content": system_content},
            {"role": "user", "content": query}
        ]

        # Loop de Tool Calling
        for iteration in range(MAX_TOOL_ITERATIONS):
            logger.info(f"Agent iteration {iteration + 1}/{MAX_TOOL_ITERATIONS}")

            # Chamar LLM com tools
            result = await self._call_llm_with_tools(messages, TOOLS_DEFINITIONS)

            # Se houve erro, usar fallback
            if result.get("error"):
                logger.error(f"LLM error: {result['error']}")
                return self._fallback_without_llm(query, doctor_id, db)

            # Se LLM respondeu SEM tool calls → é a resposta final
            if not result.get("tool_calls"):
                final_response = result.get("content", "")
                if final_response:
                    logger.info(f"Agent final response (iteration {iteration + 1}): {len(final_response)} chars")
                    return final_response
                else:
                    # LLM não retornou conteúdo nem tools — fallback
                    return self._fallback_without_llm(query, doctor_id, db)

            # LLM pediu tool calls → executar cada uma
            tool_calls = result["tool_calls"]
            logger.info(f"LLM requested {len(tool_calls)} tool call(s)")

            # Adicionar a mensagem do assistente (com tool_calls) ao histórico
            assistant_msg = {"role": "assistant", "content": result.get("content") or ""}
            assistant_msg["tool_calls"] = tool_calls
            messages.append(assistant_msg)

            # Executar cada tool e adicionar resultado ao histórico
            for tc in tool_calls:
                tool_name = tc["function"]["name"]
                try:
                    tool_args = json.loads(tc["function"]["arguments"]) if isinstance(tc["function"]["arguments"], str) else tc["function"]["arguments"]
                except (json.JSONDecodeError, TypeError):
                    tool_args = {}

                logger.info(f"Executing tool: {tool_name}({tool_args})")

                # Executar a tool
                tool_result = execute_tool(tool_name, tool_args, db)

                # Adicionar resultado ao histórico
                messages.append({
                    "role": "tool",
                    "tool_call_id": tc.get("id", f"call_{tool_name}"),
                    "content": tool_result
                })

                logger.info(f"Tool {tool_name} returned {len(tool_result)} chars")

        # Se chegou aqui, atingiu MAX_TOOL_ITERATIONS sem resposta final
        logger.warning("Agent atingiu MAX_TOOL_ITERATIONS sem resposta final")

        # Fazer uma última chamada SEM tools para forçar resposta
        messages.append({
            "role": "user",
            "content": "Por favor, responda a pergunta original do paciente com as informações que você já coletou."
        })
        final_result = await self._call_llm_with_tools(messages, tools=None)

        if final_result.get("content"):
            return final_result["content"]

        return self._fallback_without_llm(query, doctor_id, db)

    # ------------------------------------------------------------------ #
    #  FALLBACK (sem LLM)
    # ------------------------------------------------------------------ #

    def _fallback_without_llm(self, query: str, doctor_id: Optional[int], db) -> str:
        """
        Fallback quando a LLM não está disponível.
        Tenta usar as tools diretamente sem intermediação da LLM.
        """
        logger.info("Usando fallback sem LLM")

        # Tentar buscar na FAQ
        from app.services.agent_tools import buscar_faq
        faq_result = buscar_faq(pergunta=query, medico_id=doctor_id)

        if faq_result and "Nenhuma" not in faq_result and "Erro" not in faq_result:
            return (
                "⚠️ Nosso assistente IA está temporariamente indisponível, "
                "mas encontrei estas informações na nossa base:\n\n"
                f"{faq_result[:1500]}\n\n"
                "Para mais detalhes, entre em contato diretamente com a clínica."
            )

        return (
            "Desculpe, estou com dificuldades técnicas no momento. 😔\n"
            "Por favor, entre em contato diretamente com a clínica por telefone."
        )

    # ------------------------------------------------------------------ #
    #  GERENCIAMENTO DE ESTADO (APIs para endpoints)
    # ------------------------------------------------------------------ #

    def clear_conversation(self, wa_from: str):
        """Limpa o estado de uma conversa (para testes/novo atendimento)."""
        conversation_manager.clear_state(wa_from)

    def get_conversation_state(self, wa_from: str) -> dict:
        """Retorna o estado da conversa (para debug)."""
        return conversation_manager.get_state(wa_from)


# Singleton
rag_service = RAGService()
