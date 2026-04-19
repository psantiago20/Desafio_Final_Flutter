from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import logging

from app.core.config import settings
from app.db.database import engine
from app.models import user, patient, appointment, message, service
from app.api.endpoints import auth, patients, appointments, messages, dashboard, finance, whatsapp, chat, test_notifications

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="OmniConnect API",
    description="API para Gestão Inteligente de Serviços",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(patients.router, prefix="/api/patients", tags=["patients"])
app.include_router(appointments.router, prefix="/api/appointments", tags=["appointments"])
app.include_router(messages.router, prefix="/api/messages", tags=["messages"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["dashboard"])
app.include_router(finance.router, prefix="/api/finance", tags=["finance"])
app.include_router(whatsapp.router, prefix="/api/webhooks", tags=["whatsapp"])
app.include_router(chat.router, prefix="/api/chat", tags=["chat"])
app.include_router(whatsapp.router, prefix="/webhook", tags=["whatsapp-webhook"])
app.include_router(test_notifications.router, prefix="/api/test", tags=["test"])


@app.get("/")
def root():
    return {"message": "OmniConnect API", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}