"""
rag_service.py — Serviço core do RAG (Retrieval-Augmented Generation)

Pipeline completo:
1. Recebe pergunta do paciente + doctor_id
2. Busca contexto semântico na FAQ (ChromaDB)
3. Busca dados do médico no PostgreSQL (horários, serviços, etc.)
4. Monta prompt enriquecido e chama a LLM (NVIDIA Nim)
5. Retorna resposta contextualizada
"""

import json
import logging
import os
from typing import Optional, List, Dict

import httpx
import chromadb

from app.core.config import settings

logger = logging.getLogger(__name__)

CHROMA_PERSIST_DIR = os.environ.get(
    "CHROMA_DIR",
    os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data")
)


class RAGService:
    """
    Serviço RAG que combina busca semântica na FAQ (ChromaDB)
    com dados do médico (PostgreSQL) para gerar respostas contextualizadas.
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
    #  1. BUSCA SEMÂNTICA NA FAQ (ChromaDB)
    # ------------------------------------------------------------------ #

    def search_faq(
        self,
        query: str,
        doctor_id: Optional[int],
        top_k: int = 5
    ) -> List[Dict]:
        """
        Busca semântica na collection FAQ do médico.
        
        Args:
            query: Pergunta do paciente
            doctor_id: ID do médico (None = buscar apenas global)
            top_k: Número máximo de resultados
            
        Returns:
            Lista de chunks relevantes com metadados
        """
        collection_name = f"faq_doctor_{doctor_id}" if doctor_id else "faq_global"

        try:
            collection = self.chroma_client.get_collection(collection_name)
        except Exception:
            # Collection não existe — tentar fallback para global
            logger.warning(f"Collection '{collection_name}' não encontrada. Tentando faq_doctor_0...")
            try:
                collection = self.chroma_client.get_collection("faq_doctor_0")
            except Exception:
                logger.warning("Nenhuma collection FAQ encontrada no ChromaDB")
                return []

        try:
            results = collection.query(
                query_texts=[query],
                n_results=min(top_k, collection.count()) if collection.count() > 0 else 1
            )
        except Exception as e:
            logger.error(f"Erro na busca semântica: {e}")
            return []

        # Formatar resultados
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

        logger.info(f"FAQ search: {len(chunks)} chunks encontrados para doctor_id={doctor_id}")
        return chunks

    # ------------------------------------------------------------------ #
    #  2. BUSCA DE DADOS DO MÉDICO NO POSTGRESQL
    # ------------------------------------------------------------------ #

    def get_doctor_context(self, doctor_id: Optional[int], db) -> str:
        """
        Busca dados dinâmicos do médico no PostgreSQL e formata como contexto.
        
        Inclui: nome, especialidades, horários, convênios, endereço, serviços.
        """
        if doctor_id is None:
            return ""

        from app.models.doctor_profile import DoctorProfile
        from app.models.user import User
        from app.models.service import Service

        try:
            # Buscar perfil do médico
            profile = db.query(DoctorProfile).filter(
                DoctorProfile.id == doctor_id
            ).first()

            if not profile:
                # Tentar por user_id
                profile = db.query(DoctorProfile).filter(
                    DoctorProfile.user_id == doctor_id
                ).first()

            if not profile:
                logger.info(f"DoctorProfile não encontrado para doctor_id={doctor_id}")
                return ""

            # Buscar dados do usuário
            user = db.query(User).filter(User.id == profile.user_id).first()

            # Buscar serviços disponíveis
            services = db.query(Service).filter(
                Service.patient_id == None  # Serviços "template" do médico
            ).limit(20).all()

            # Montar contexto estruturado
            context_parts = []

            if user:
                context_parts.append(f"**Médico**: {user.full_name or user.username}")

            if profile.clinic_name:
                context_parts.append(f"**Clínica**: {profile.clinic_name}")

            if profile.specialties:
                try:
                    specs = json.loads(profile.specialties)
                    context_parts.append(f"**Especialidades**: {', '.join(specs)}")
                except (json.JSONDecodeError, TypeError):
                    context_parts.append(f"**Especialidades**: {profile.specialties}")

            if profile.working_hours:
                try:
                    hours = json.loads(profile.working_hours)
                    hours_str = ", ".join([f"{k}: {v}" for k, v in hours.items()])
                    context_parts.append(f"**Horários**: {hours_str}")
                except (json.JSONDecodeError, TypeError):
                    context_parts.append(f"**Horários**: {profile.working_hours}")

            if profile.accepted_insurances:
                try:
                    insurances = json.loads(profile.accepted_insurances)
                    context_parts.append(f"**Convênios aceitos**: {', '.join(insurances)}")
                except (json.JSONDecodeError, TypeError):
                    context_parts.append(f"**Convênios aceitos**: {profile.accepted_insurances}")

            if profile.clinic_address:
                context_parts.append(f"**Endereço**: {profile.clinic_address}")

            if profile.clinic_phone:
                context_parts.append(f"**Telefone**: {profile.clinic_phone}")

            if profile.consultation_price:
                context_parts.append(f"**Valor da consulta**: {profile.consultation_price}")

            if profile.consultation_duration:
                context_parts.append(f"**Duração da consulta**: {profile.consultation_duration} minutos")

            if services:
                service_names = [s.name for s in services[:10]]
                context_parts.append(f"**Serviços disponíveis**: {', '.join(service_names)}")

            context = "\n".join(context_parts)
            logger.info(f"Contexto do médico montado ({len(context)} chars)")
            return context

        except Exception as e:
            logger.error(f"Erro ao buscar contexto do médico: {e}")
            return ""

    # ------------------------------------------------------------------ #
    #  3. CHAMADA À LLM (NVIDIA Nim)
    # ------------------------------------------------------------------ #

    async def _call_llm(
        self,
        user_message: str,
        faq_context: str,
        doctor_context: str
    ) -> str:
        """
        Chama a LLM (NVIDIA Nim) com o prompt enriquecido pelo RAG.
        """
        if not self.api_key:
            return self._fallback_response(user_message, faq_context)

        # Montar prompt do sistema
        system_prompt = (
            "Você é o assistente virtual do OmniConnect, uma plataforma de gestão médica. "
            "Você ajuda pacientes a agendar consultas, tirar dúvidas sobre exames, "
            "horários, preparos e informações gerais da clínica.\n\n"
            "REGRAS IMPORTANTES:\n"
            "- Responda SEMPRE em português brasileiro.\n"
            "- Seja profissional, gentil e conciso.\n"
            "- Use APENAS as informações do contexto abaixo para responder.\n"
            "- Se a informação não estiver no contexto, diga que não tem essa informação "
            "e sugira que o paciente entre em contato diretamente com a clínica.\n"
            "- NUNCA invente informações sobre horários, preços ou procedimentos.\n"
            "- Formate a resposta de forma amigável para WhatsApp (use emojis com moderação).\n"
        )

        if doctor_context:
            system_prompt += f"\n--- DADOS DO MÉDICO/CLÍNICA ---\n{doctor_context}\n"

        if faq_context:
            system_prompt += f"\n--- BASE DE CONHECIMENTO (FAQ) ---\n{faq_context}\n"

        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            "temperature": 0.3,  # Mais determinístico para respostas factuais
            "max_tokens": 1024
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                if response.status_code != 200:
                    logger.error(f"NVIDIA API Error: {response.text}")
                    return self._fallback_response(user_message, faq_context)

                result = response.json()
                return result["choices"][0]["message"]["content"]
            except Exception as e:
                logger.error(f"Erro ao chamar NVIDIA Nim: {e}")
                return self._fallback_response(user_message, faq_context)

    def _fallback_response(self, user_message: str, faq_context: str) -> str:
        """
        Resposta de fallback quando a LLM não está disponível.
        Retorna o contexto da FAQ diretamente se encontrado.
        """
        if faq_context:
            return (
                "⚠️ Nosso assistente IA está temporariamente indisponível, "
                "mas encontrei estas informações que podem ajudar:\n\n"
                f"{faq_context[:1500]}\n\n"
                "Para mais detalhes, entre em contato diretamente com a clínica."
            )
        return (
            "Desculpe, estou com dificuldades técnicas no momento. "
            "Por favor, entre em contato diretamente com a clínica por telefone."
        )

    # ------------------------------------------------------------------ #
    #  4. PIPELINE RAG COMPLETO
    # ------------------------------------------------------------------ #

    async def get_rag_response(
        self,
        query: str,
        doctor_id: Optional[int],
        db,
        top_k: int = 5
    ) -> str:
        """
        Pipeline RAG completo:
        1. Busca semântica na FAQ do médico (ChromaDB)
        2. Busca dados dinâmicos do médico (PostgreSQL)
        3. Chama LLM com contexto enriquecido
        
        Args:
            query: Pergunta do paciente
            doctor_id: ID do DoctorProfile (None = sem médico específico)
            db: Sessão do banco SQLAlchemy
            top_k: Quantidade de chunks FAQ a buscar
            
        Returns:
            Resposta gerada pela LLM com contexto RAG
        """
        logger.info(f"RAG Pipeline: query='{query[:80]}...' doctor_id={doctor_id}")

        # 1. Busca semântica na FAQ
        faq_chunks = self.search_faq(query, doctor_id, top_k=top_k)
        faq_context = "\n\n".join([chunk["content"] for chunk in faq_chunks])
        logger.info(f"FAQ: {len(faq_chunks)} chunks, {len(faq_context)} chars de contexto")

        # 2. Busca dados do médico no PostgreSQL
        doctor_context = self.get_doctor_context(doctor_id, db)
        logger.info(f"Doctor context: {len(doctor_context)} chars")

        # 3. Chamar LLM
        response = await self._call_llm(query, faq_context, doctor_context)

        logger.info(f"RAG response generated ({len(response)} chars)")
        return response

    # ------------------------------------------------------------------ #
    #  5. BUSCA SIMPLES (sem LLM, apenas retorna chunks)
    # ------------------------------------------------------------------ #

    def search_only(
        self,
        query: str,
        doctor_id: Optional[int],
        top_k: int = 5
    ) -> List[Dict]:
        """
        Retorna apenas os chunks da FAQ sem chamar a LLM.
        Útil para debug e testes.
        """
        return self.search_faq(query, doctor_id, top_k)


# Singleton
rag_service = RAGService()
