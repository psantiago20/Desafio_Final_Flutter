from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "OmniConnect"
    DEBUG: bool = True
    
    DATABASE_URL: str = "postgresql://omniconnect:omniconnect123@localhost:5432/omniconnect"
    
    SECRET_KEY: str = "supersecretkeychangeinproduction"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    NVIDIA_API_KEY: str = ""
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama2"
    
    WHATSAPP_VERIFY_TOKEN: str = "desafio-ciclo"
    WHATSAPP_WEBHOOK_SECRET: str = "desafio-ciclo"
    WHATSAPP_PHONE_NUMBER_ID: str = ""
    WHATSAPP_ACCESS_TOKEN: str = ""
    WHATSAPP_CALLBACK_URL: str = ""
    WHATSAPP_BUSINESS_ACCOUNT_ID: str = ""
    
    FCM_SERVER_KEY: str = ""
    
    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()


settings = get_settings()