from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "OmniConnect"
    DEBUG: bool = True
    
    # Usa SQLite como fallback para testes locais (sem Docker/PostgreSQL)
    # Em produção, definir DATABASE_URL como variável de ambiente para PostgreSQL
    DATABASE_URL: str = "sqlite:///./omniconnect_test.db"
    
    SECRET_KEY: str = "supersecretkeychangeinproduction"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    NVIDIA_API_KEY: str = ""
    GROQ_API_KEY: str = ""  # Tier gratuito — console.groq.com (sem cartão)
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama2"
    
    WHATSAPP_VERIFY_TOKEN: str = "desafio-ciclo"
    WHATSAPP_WEBHOOK_SECRET: str = "desafio-ciclo"
    WHATSAPP_PHONE_NUMBER_ID: str = ""
    WHATSAPP_ACCESS_TOKEN: str = ""
    WHATSAPP_CALLBACK_URL: str = ""
    WHATSAPP_BUSINESS_ACCOUNT_ID: str = ""
    
    FCM_SERVER_KEY: str = ""
    
    LANGSMITH_API_KEY: str = ""
    LANGSMITH_TRACING: bool = True
    LANGSMITH_PROJECT: str = "OmniConnect-Evolution"

    
    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()


settings = get_settings()