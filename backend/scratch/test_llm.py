import os
import asyncio
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.messages import HumanMessage

async def test_llm():
    api_key = "nvapi-..." # Eu preciso da chave real ou ler do .env
    # No meu caso, ela está no settings.NVIDIA_API_KEY
    
    # Mas eu posso tentar importar do app
    import sys
    sys.path.append(os.getcwd())
    from app.core.config import settings
    
    print(f"Testando LLM com chave: {settings.NVIDIA_API_KEY[:10]}...")
    
    llm = ChatNVIDIA(
        model="meta/llama-3.1-8b-instruct",
        nvidia_api_key=settings.NVIDIA_API_KEY,
        temperature=0.2
    )
    
    try:
        response = await llm.ainvoke([HumanMessage(content="Olá, você está funcionando?")])
        print(f"Resposta: {response.content}")
    except Exception as e:
        print(f"Erro: {e}")

if __name__ == "__main__":
    asyncio.run(test_llm())
