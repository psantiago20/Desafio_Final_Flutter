import logging
import json
import base64
from typing import Optional, Tuple
from io import BytesIO
from pypdf import PdfReader
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_groq import ChatGroq
from langchain_core.messages import HumanMessage, SystemMessage
from app.core.config import settings

logger = logging.getLogger(__name__)

class ContentModerationService:
    def __init__(self):
        # Inicializa as LLMs baseadas nas chaves disponíveis
        if settings.GROQ_API_KEY:
            self.llm = ChatGroq(
                model="llama-3.3-70b-versatile",
                api_key=settings.GROQ_API_KEY,
                temperature=0.0,
                max_tokens=150
            )
        else:
            self.llm = ChatNVIDIA(
                model="meta/llama-3.1-8b-instruct",
                nvidia_api_key=settings.NVIDIA_API_KEY,
                temperature=0.0
            )

        # Vision Model para Imagens
        self.vision_model = ChatNVIDIA(
            model="meta/llama-3.2-11b-vision-instruct",
            nvidia_api_key=settings.NVIDIA_API_KEY,
            temperature=0.0
        )

    async def check_text_safety(self, text: str) -> Tuple[bool, Optional[str]]:
        """
        Analisa um texto e determina se ele viola as diretrizes de segurança.
        Retorna (is_safe, reason).
        """
        if not text or not text.strip():
            return True, None

        prompt = (
            "Você é um classificador de segurança de conteúdo extremamente rígido para uma clínica médica de atendimento ao cliente.\n"
            "Sua tarefa é analisar o texto do usuário e identificar se ele contém qualquer violação das seguintes políticas de segurança:\n"
            "1. Conteúdo Sexual / Pornografia / Erotismo explícito.\n"
            "2. Exploração ou abuso infantil, ou qualquer menção a pornografia infantil. (Tolerância Zero!)\n"
            "3. Discurso de Ódio, assédio moral ou sexual, xingamentos direcionados, racismo, homofobia ou intolerância religiosa.\n"
            "4. Violência extrema, apologia à automutilação, suicídio, terrorismo ou fabricação de armas/drogas.\n"
            "5. Golpes, fraudes cibernéticas ou tentativas de engenharia social.\n"
            "\n"
            "IMPORTANTE: Dúvidas sobre saúde geral, exames íntimos legítimos (como exames ginecológicos, urológicos), termos anatômicos normais, ou ferimentos reais que os pacientes relatam são PERMITIDOS e devem ser classificados como SEGUROS.\n"
            "\n"
            "Retorne APENAS um objeto JSON válido, sem blocos de código markdown (como ```json) ou texto explicativo. O JSON deve ter exatamente este formato:\n"
            "{\n"
            "  \"safe\": true ou false,\n"
            "  \"reason\": \"Se safe for false, explique resumidamente em português a violação encontrada (ex: 'Discurso de ódio' ou 'Conteúdo impróprio'). Se for seguro, deixe vazio.\"\n"
            "}\n"
            f"TEXTO A SER ANALISADO: \"{text}\""
        )

        try:
            logger.info("[Moderation] Iniciando moderação de texto...")
            response = self.llm.invoke([HumanMessage(content=prompt)])
            content = response.content.replace("```json", "").replace("```", "").strip()
            
            # Tentar decodificar JSON
            data = json.loads(content)
            is_safe = data.get("safe", True)
            reason = data.get("reason", None)
            
            # Normalizar para None se for vazio/falso
            reason = reason or None
            
            if not is_safe:
                logger.warning(f"[Moderation BLOCKED] Texto bloqueado por: {reason}")
            return is_safe, reason
        except Exception as e:
            logger.error(f"[Moderation Error] Erro ao moderar texto: {e}")
            # Em caso de falha técnica, permitimos a passagem por padrão para não interromper o serviço,
            # ou bloqueamos se formos ultra-restritivos. Aqui permitimos mas logamos o erro.
            return True, None

    async def check_image_safety(self, image_bytes: bytes, mime_type: str) -> Tuple[bool, Optional[str]]:
        """
        Analisa uma imagem para detectar pornografia, pornografia infantil, violência extrema ou símbolos de ódio.
        Retorna (is_safe, reason).
        """
        if not settings.NVIDIA_API_KEY:
            logger.warning("[Moderation] NVIDIA_API_KEY não configurada. Moderação de imagem indisponível.")
            return True, None

        try:
            logger.info("[Moderation] Iniciando moderação de imagem com Llama-Vision...")
            encoded_image = base64.b64encode(image_bytes).decode("utf-8")
            
            prompt = (
                "Você é um moderador de segurança visual extremamente rígido para uma clínica médica de atendimento ao cliente.\n"
                "Analise a imagem fornecida. Determine se a imagem viola alguma das seguintes políticas:\n"
                "1. Pornografia, nudez explícita, atos sexuais ou erotismo.\n"
                "2. Exploração sexual ou abuso infantil. (Tolerância Zero!)\n"
                "3. Violência extrema, mutilação, decapitações ou terrorismo.\n"
                "4. Símbolos de ódio ou imagens ofensivas e discriminatórias.\n"
                "\n"
                "IMPORTANTE: Imagens de exames médicos legítimos (raios-X, ultrassons), fotos de pele com lesões dermatológicas, ferimentos reais ou exames reais enviados por pacientes para diagnóstico legítimo são PERMITIDOS e devem ser classificados como SEGUROS.\n"
                "\n"
                "Retorne APENAS um objeto JSON válido no seguinte formato, sem qualquer texto adicional ou blocos de código markdown:\n"
                "{\n"
                "  \"safe\": true ou false,\n"
                "  \"reason\": \"Se safe for false, explique o motivo em português. Se safe for true, deixe em branco.\"\n"
                "}"
            )
            
            message = HumanMessage(
                content=[
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:{mime_type};base64,{encoded_image}"}},
                ]
            )
            
            response = self.vision_model.invoke([message])
            content = response.content.replace("```json", "").replace("```", "").strip()
            
            data = json.loads(content)
            is_safe = data.get("safe", True)
            reason = data.get("reason", None)
            
            # Normalizar para None se for vazio/falso
            reason = reason or None
            
            if not is_safe:
                logger.warning(f"[Moderation BLOCKED] Imagem bloqueada por: {reason}")
            return is_safe, reason
        except Exception as e:
            logger.error(f"[Moderation Error] Erro ao moderar imagem: {e}")
            return True, None

    async def check_pdf_safety(self, pdf_bytes: bytes) -> Tuple[bool, Optional[str]]:
        """
        Extrai o texto de um PDF e roda a moderação de texto nele.
        """
        try:
            logger.info("[Moderation] Iniciando moderação de PDF...")
            reader = PdfReader(BytesIO(pdf_bytes))
            text_content = ""
            for page in reader.pages:
                text_content += page.extract_text() + "\n"
            
            if not text_content.strip():
                # PDF vazio ou escaneado sem OCR
                return True, None

            # Limita a análise aos primeiros 6000 caracteres para evitar sobrecarregar a janela de contexto da LLM
            return await self.check_text_safety(text_content[:6000])
        except Exception as e:
            logger.error(f"[Moderation Error] Erro ao moderar PDF: {e}")
            return True, None

# Singleton
content_moderation_service = ContentModerationService()
