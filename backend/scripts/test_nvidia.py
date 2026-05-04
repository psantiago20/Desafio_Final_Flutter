
import os
import sys
# Adicionar backend ao path
sys.path.append(os.path.join(os.getcwd(), "backend"))

from app.core.config import settings
from langchain_nvidia_ai_endpoints import ChatNVIDIA

def test_nvidia():
    print(f"Testando NVIDIA API Key: {settings.NVIDIA_API_KEY[:10]}...")
    try:
        llm = ChatNVIDIA(model="meta/llama-3.1-8b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY)
        resp = llm.invoke("Olá, você está funcionando?")
        print(f"Resposta: {resp.content}")
    except Exception as e:
        print(f"Erro ao chamar NVIDIA: {e}")

if __name__ == "__main__":
    test_nvidia()
