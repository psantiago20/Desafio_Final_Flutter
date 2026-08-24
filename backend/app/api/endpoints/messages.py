from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, joinedload
from typing import Optional

from app.db.database import get_db
from app.models.message import Message
from app.schemas.message import MessageCreate, MessageUpdate, MessageResponse, MessageListResponse
from app.api.endpoints.auth import get_current_user
from app.models.user import User
from datetime import datetime, timedelta
from app.services.fcm_service import fcm_service

router = APIRouter()


@router.get("", response_model=MessageListResponse)
def list_messages(
    skip: int = 0,
    limit: int = 100,
    patient_id: Optional[int] = None,
    unread_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Message).options(joinedload(Message.patient))
    
    # Se for paciente, filtra apenas as suas mensagens
    if current_user.role == "patient":
        from app.models.patient import Patient
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if patient:
            query = query.filter(Message.patient_id == patient.id)
        else:
            return {"total": 0, "messages": []}
    else:
        # Lógica para médicos
        if patient_id:
            query = query.filter(Message.patient_id == patient_id)
            
        # Se for especificamente o chat da Isis (ID 15), filtra apenas o histórico deste médico
        if patient_id == 15:
            query = query.filter((Message.sender_id == current_user.id) | (Message.receiver_id == current_user.id))
        else:
            # Garante que o médico só veja:
            # 1. Mensagens que têm um remetente ou destinatário definido
            # 2. Mensagens do canal do WhatsApp (ou respostas da IA para o WhatsApp)
            # Isso esconde a conversa privada do paciente com a IA no aplicativo móvel
            query = query.filter(
                (Message.sender_id.isnot(None)) | 
                (Message.receiver_id.isnot(None)) |
                (Message.source.in_(["whatsapp", "ai", "bot", "app_doctor"]))
            )
    
    if unread_only:
        query = query.filter(Message.is_read == False)
    
    total = query.count()
    messages = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    
    return {"total": total, "messages": messages}


@router.get("/{message_id}", response_model=MessageResponse)
def get_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    message = db.query(Message).options(joinedload(Message.patient)).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    return message


@router.post("", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_message = Message(
        **message.model_dump(exclude={"sender_id"}),
        sender_id=current_user.id
    )
    db.add(db_message)
    db.commit()
    db.refresh(db_message)
    
    # --- FCM Notification Logic ---
    if db_message.receiver_id:
        from app.services.fcm_service import fcm_service
        from app.models.user import User
        receiver = db.query(User).filter(User.id == db_message.receiver_id).first()
        if receiver and receiver.fcm_token:
            sender_name = current_user.full_name or current_user.username or "A user"
            fcm_service.send_notification(
                token=receiver.fcm_token,
                title=f"Nova mensagem de {sender_name}",
                body=db_message.content if db_message.message_type == "text" else "Enviou um anexo",
                data={"type": "chat_message", "sender_id": str(current_user.id)}
            )

    # --- WhatsApp Notification Logic (Web Only) ---
    from app.services.whatsapp_service import wa_service
    from app.models.patient import Patient
    import asyncio

    patient = db.query(Patient).filter(Patient.id == db_message.patient_id).first()
    
    if current_user.role == "doctor" and patient and patient.phone:
        wa_message = f"Olá {patient.name}, o Dr. {current_user.full_name} enviou uma nova mensagem para você no portal. Acesse para responder!"
        print(f"[WHATSAPP] Gatilho de mensagem de chat acionado via WEB para: {patient.name} ({patient.phone})")
        asyncio.create_task(wa_service.send_message(patient.phone, wa_message))

    return db_message


@router.put("/{message_id}", response_model=MessageResponse)
def update_message(
    message_id: int,
    message: MessageUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_message = db.query(Message).filter(Message.id == message_id).first()
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    update_data = message.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_message, key, value)
    
    db.commit()
    db.refresh(db_message)
    return db_message


@router.patch("/read-all/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def mark_patient_messages_as_read(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Message).filter(
        Message.patient_id == patient_id,
        Message.is_read == False
    )
    
    if current_user.role == "patient":
        # Paciente lendo mensagens recebidas (bot ou médico)
        # Excluímos as enviadas por ele
        query = query.filter(Message.sender_id != current_user.id)
    else:
        # Médico lendo mensagens do paciente
        query = query.filter(Message.sender_id != current_user.id)
        
    query.update({Message.is_read: True})
    db.commit()
    return None
