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
    elif patient_id:
        query = query.filter(Message.patient_id == patient_id)
    
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
def create_message(
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
        # Debounce: check if sender sent a message to this receiver in the last 1 minute
        one_minute_ago = datetime.utcnow() - timedelta(minutes=1)
        recent_msg_count = db.query(Message).filter(
            Message.sender_id == current_user.id,
            Message.receiver_id == db_message.receiver_id,
            Message.created_at >= one_minute_ago,
            Message.id != db_message.id
        ).count()

        if recent_msg_count == 0:
            receiver = db.query(User).filter(User.id == db_message.receiver_id).first()
            if receiver and receiver.fcm_token:
                # Payload limits handling
                if db_message.message_type != "text":
                    body_text = f"Sent an attachment ({db_message.message_type})"
                else:
                    body_text = db_message.content

                sender_name = current_user.full_name or current_user.username or "A user"
                
                # Check online status (if we had a websocket, but for now we just use the token)
                fcm_service.send_notification(
                    token=receiver.fcm_token,
                    title=f"New message from {sender_name}",
                    body=body_text,
                    data={
                        "type": "chat_message",
                        "message_id": str(db_message.id),
                        "sender_id": str(current_user.id)
                    }
                )
                
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


@router.patch("/{message_id}/read", status_code=status.HTTP_204_NO_CONTENT)
def mark_as_read(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_message = db.query(Message).filter(Message.id == message_id).first()
    if not db_message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    db_message.is_read = True
    db.commit()
    return None
