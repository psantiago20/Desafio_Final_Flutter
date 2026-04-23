from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List

from app.db.database import get_db
from app.models.patient import Patient
from app.models.message import Message
from app.api.endpoints.auth import get_current_user
from app.models.user import User

router = APIRouter()


class ChatMessage(BaseModel):
    message: str
    patient_id: Optional[int] = None


class ChatResponse(BaseModel):
    response: str
    patient_id: Optional[int] = None
    suggested_action: Optional[str] = None


class AIChatService:
    def __init__(self, db: Session):
        self.db = db
    
    async def process_message(self, user_message: str, patient_id: Optional[int] = None) -> ChatResponse:
        response_text = "Mensagem recebida. Como posso ajudar?"
        suggested_action = None
        
        user_lower = user_message.lower()
        
        if any(word in user_lower for word in ["agendar", "consulta", "horário", "marcar"]):
            response_text = "Para agendar uma consulta, preciso de algumas informações:\n1. Seu nome completo\n2. CPF\n3. Convênio (se tiver)\n4. Preferência de dia e horário"
            suggested_action = "schedule_appointment"
        
        elif any(word in user_lower for word in ["retorno", "revisar", "rever"]):
            response_text = "Para agendar retorno, me informe o CPF usedo na última consulta."
            suggested_action = "schedule_return"
        
        elif any(word in user_lower for word in ["exame", "resultado"]):
            response_text = "Posso ajudar com resultados de exames. Pode me informar seu CPF para consultar?"
            suggested_action = "check_exams"
        
        elif any(word in user_lower for word in ["cancelar", "desmarcar", "remarcar"]):
            response_text = "Para cancelar ou remarcar, preciso do CPF do paciente e motivo."
            suggested_action = "reschedule"
        
        elif any(word in user_lower for word in ["endereço", "local", "onde"]):
            response_text = "Estamos localizados na Rua example, 123 - Centro. Estacionamento gratuito disponível."
            suggested_action = "location"
        
        elif any(word in user_lower for word in ["contato", "telefone", "whatsapp", "ligar"]):
            response_text = "Nosso telefone é (11) 99999-9999. WhatsApp: (11) 99999-9999"
            suggested_action = "contact"
        
        if patient_id:
            patient = db.query(Patient).filter(Patient.id == patient_id).first()
            if patient:
                db_message = Message(
                    patient_id=patient_id,
                    content=user_message,
                    message_type="text",
                    source="whatsapp",
                    is_delivered=True
                )
                self.db.add(db_message)
                self.db.commit()
        
        return ChatResponse(
            response=response_text,
            patient_id=patient_id,
            suggested_action=suggested_action
        )


@router.post("/ia", response_model=ChatResponse)
async def chat_with_ia(
    chat_message: ChatMessage,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    ai_service = AIChatService(db)
    return await ai_service.process_message(chat_message.message, chat_message.patient_id)


@router.post("/whatsapp", response_model=ChatResponse)
async def chat_whatsapp_ia(
    message: str,
    wa_from: str,
    db: Session = Depends(get_db)
):
    patient = db.query(Patient).filter(Patient.whatsapp == wa_from).first()
    
    if not patient:
        patient = Patient(
            name=f"WhatsApp User {wa_from[-4:]}",
            phone=wa_from,
            whatsapp=wa_from
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
    
    ai_service = AIChatService(db)
    response = await ai_service.process_message(message, patient.id)
    
    db_message = Message(
        patient_id=patient.id,
        content=message,
        message_type="text",
        source="whatsapp",
        wa_from=wa_from,
        is_delivered=True
    )
    db.add(db_message)
    db.commit()
    
    return response