import httpx
import logging
import os
from app.core.config import settings

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self):
        self.api_key = settings.NVIDIA_API_KEY
        self.base_url = "https://integrate.api.nvidia.com/v1"
        self.model = "meta/llama-3.1-8b-instruct"
        
    def _load_pdf_context(self) -> str:
        """Carrega o conteúdo extraído dos PDFs para servir de contexto."""
        try:
            # Tentar ler o arquivo do scratch (ajustar caminho se necessário)
            # Se estiver rodando da pasta /backend, o scratch está no nível acima
            current_dir = os.getcwd()
            if os.path.basename(current_dir) == "backend":
                scratch_dir = os.path.join(os.path.dirname(current_dir), "scratch")
            else:
                scratch_dir = os.path.join(current_dir, "scratch")
                
            scratch_path = os.path.join(scratch_dir, "pdf_content.txt")
            if os.path.exists(scratch_path):
                with open(scratch_path, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read()[:4000] # Limitar contexto para não estourar o prompt
            return "Nenhum documento médico encontrado na base de conhecimento."
        except Exception as e:
            logger.error(f"Erro ao carregar contexto do PDF: {e}")
            return ""

    async def get_ai_response(self, user_message: str) -> str:
        if not self.api_key:
            return "IA está em modo offline (chave NVIDIA não configurada). Como posso ajudar?"

        context = self._load_pdf_context()
        
        url = f"{self.base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": [
                {
                    "role": "system",
                    "content": (
                        "Você é o OmniConnect AI, um assistente médico inteligente. "
                        "Responda de forma profissional e concisa. Use o contexto abaixo para responder se relevante. "
                        f"\n\nContexto dos Documentos:\n{context}"
                    )
                },
                {"role": "user", "content": user_message}
            ],
            "temperature": 0.5,
            "max_tokens": 1024
        }

        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                if response.status_code != 200:
                    logger.error(f"NVIDIA API Error: {response.text}")
                    return "Desculpe, tive um problema ao processar sua pergunta. Pode repetir?"
                
                result = response.json()
                return result["choices"][0]["message"]["content"]
            except Exception as e:
                import traceback
                logger.error(f"Erro ao chamar NVIDIA Nim: {e}")
                logger.error(traceback.format_exc())
                return "Estou com dificuldades técnicas para acessar minha inteligência agora."


ai_service = AIService()
