from app.api.endpoints.auth import router as auth_router
from app.api.endpoints.patients import router as patients_router
from app.api.endpoints.appointments import router as appointments_router
from app.api.endpoints.messages import router as messages_router
from app.api.endpoints.dashboard import router as dashboard_router
from app.api.endpoints.finance import router as finance_router
from app.api.endpoints.whatsapp import router as whatsapp_router

__all__ = [
    "auth_router", "patients_router", "appointments_router",
    "messages_router", "dashboard_router", "finance_router", "whatsapp_router"
]