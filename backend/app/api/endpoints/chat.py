from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List
import logging

from app.db.database import get_db
from app.models.patient import Patient
from app.models.message import Message
from app.api.endpoints.auth import get_current_user
from app.models.user import User
from app.services.rag_service import rag_service
from app.utils.phone_utils import find_patient_by_messaging_phone
from app.core.config import settings
from fastapi import status

router = APIRouter()
logger = logging.getLogger(__name__)

class ChatMessage(BaseModel):
    message: str
    patient_id: Optional[int] = None
    source: Optional[str] = None

class ChatResponse(BaseModel):
    response: str
    patient_id: Optional[int] = None
    suggested_action: Optional[str] = None

@router.post("/ia", response_model=ChatResponse)
async def chat_with_ia(
    chat_message: ChatMessage,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Endpoint de chat principal do App que agora utiliza o RAGService.
    Integra busca semântica em FAQs e dados do médico.
    """
    try:
        # Tentar identificar o número do WhatsApp do paciente se o patient_id for fornecido
        wa_from = None
        if chat_message.patient_id:
            patient = db.query(Patient).filter(Patient.id == chat_message.patient_id).first()
            if patient:
                wa_from = (
                    patient.whatsapp
                    or patient.phone
                    or (current_user.phone if current_user.phone else None)
                )

        # Se não houver patient_id ou número, usar o ID do usuário logado como fallback para estado
        if not wa_from:
            wa_from = current_user.phone
        if not wa_from:
            wa_from = f"user_{current_user.id}"

        # Obter resposta do RAG
        response_text = await rag_service.get_rag_response(
            query=chat_message.message,
            wa_to=None,
            db=db,
            wa_from=wa_from,
            source=chat_message.source if chat_message.source else current_user.role,
            user_name=current_user.full_name,
            user_id=current_user.id
        )

        # Salvar mensagem no histórico
        target_patient_id = chat_message.patient_id or 15 # ID 15 é a Isis (Assistente)
        
        # Salvar mensagem do usuário
        db_message = Message(
            patient_id=target_patient_id,
            sender_id=current_user.id,
            content=chat_message.message,
            message_type="text",
            source="app",
            is_delivered=True
        )
        db.add(db_message)
        
        # Salvar resposta da IA
        ai_message = Message(
            patient_id=target_patient_id,
            receiver_id=current_user.id,
            content=response_text,
            message_type="text",
            source="system",
            is_delivered=True,
            wa_from="isis_ia"
        )
        db.add(ai_message)
        db.commit()

        return ChatResponse(
            response=response_text,
            patient_id=chat_message.patient_id,
            suggested_action=None # O RAGService agora gerencia a intenção
        )
    except Exception as e:
        logger.error(f"Erro no chat com IA: {e}")
        raise HTTPException(status_code=500, detail="Erro ao processar sua mensagem pelo assistente IA.")

@router.post("/whatsapp", response_model=ChatResponse)
async def chat_whatsapp_ia(
    message: str,
    wa_from: str,
    db: Session = Depends(get_db)
):
    """
    Endpoint legado ou de integração direta para simulação WhatsApp.
    """
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    patient = find_patient_by_messaging_phone(db, wa_from)

    if not patient:
        patient = Patient(
            name=f"WhatsApp User {wa_from[-4:]}",
            phone=wa_from,
            whatsapp=wa_from
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
    
    response_text = await rag_service.get_rag_response(
        query=message,
        wa_to=None,
        db=db,
        wa_from=wa_from
    )
    
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
    
    return ChatResponse(
        response=response_text,
        patient_id=patient.id
    )