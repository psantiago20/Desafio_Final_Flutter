from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime

from app.db.database import get_db
from app.models.patient import Patient
from app.models.appointment import Appointment
from app.services.whatsapp_service import wa_service
from app.core.config import settings
from fastapi import status

router = APIRouter()


class TestNotificationRequest(BaseModel):
    phone: str
    message: str


@router.post("/test-notification")
async def test_notification(request: TestNotificationRequest):
    """Endpoint para testar notificação via WhatsApp"""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    try:
        result = await wa_service.send_message(request.phone, request.message)
        return {"status": "success", "wa_response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/test-appointment-notification")
async def test_appointment_notification(phone: str, patient_name: str, date: str, time: str):
    """Endpoint para testar notificação de agendamento"""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    message = f"Olá {patient_name}! Sua consulta foi agendada para {date} às {time}. Para confirmar ou cancelar, responda esta mensagem."
    
    try:
        result = await wa_service.send_message(phone, message)
        return {"status": "success", "message": message, "wa_response": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/test-create-patient")
def test_create_patient(db: Session = Depends(get_db)):
    """Cria paciente de teste para verificar fluxo"""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    patient = Patient(
        name="Paciente Teste",
        phone="5515981829743",
        whatsapp="5515981829743"
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return {"patient_id": patient.id, "phone": patient.whatsapp}