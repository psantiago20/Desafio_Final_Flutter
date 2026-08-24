# Forçando reload
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import logging

print("[DEBUG] Importando core.config...")
from app.core.config import settings
print("[DEBUG] Importando database...")
from app.db.database import engine
print("[DEBUG] Importando models...")
from app.models import user, patient, appointment, message, service, doctor_profile, medico, exam
print("[DEBUG] Importando endpoints...")
from app.api.endpoints import auth, patients, appointments, messages, dashboard, finance, whatsapp, chat, test_notifications, rag, simulator_admin, medicos, exams
print("[DEBUG] Imports concluídos!")

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("backend_debug.log")
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="OmniConnect API",
    description="API para Gestão Inteligente de Serviços",
    version="1.0.0"
)

# Log de Requisições para Debug + Forced CORS + Error Capture
@app.middleware("http")
async def log_requests(request, call_next):
    try:
        # Log simplificado para evitar vazamento de PII em URLs
        logger.info(f"Request: {request.method} {request.url.path}")
        response = await call_next(request)
        return response
    except Exception as e:
        import traceback
        error_msg = traceback.format_exc()
        logger.error(f"[CRITICAL ERROR] {error_msg}")
        
        # Só retorna o traceback completo se estiver em modo DEBUG
        content = {"detail": "Internal Server Error"}
        if settings.DEBUG:
            content["traceback"] = error_msg
            
        from fastapi.responses import JSONResponse
        return JSONResponse(
            status_code=500,
            content=content
        )

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
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
app.include_router(rag.router, prefix="/api/rag", tags=["rag"])
app.include_router(simulator_admin.router, prefix="/api/simulator", tags=["simulator"])
app.include_router(medicos.router, prefix="/api/medicos", tags=["medicos"])
app.include_router(exams.router, prefix="/api/exams", tags=["exams"])

from app.core.scheduler import start_scheduler

@app.on_event("startup")
async def startup_event():
    logger.info("Initializing background tasks...")
    start_scheduler()

@app.get("/")
def root():
    return {"message": "OmniConnect API", "version": "1.0.0"}


@app.get("/health")
def health_check():
    return {"status": "healthy"}


# Servir arquivos estáticos (simulador de chat)
import os
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse

static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

# Servir o frontend do Flutter
frontend_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "frontend", "build", "web")
if os.path.exists(frontend_dir):
    app.mount("/app", StaticFiles(directory=frontend_dir, html=True), name="frontend")

@app.get("/chat")
def chat_simulator_redirect():
    """Redireciona para o simulador de chat"""
    return RedirectResponse(url="/static/chat_simulator.html")