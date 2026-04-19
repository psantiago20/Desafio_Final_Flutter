from fastapi import APIRouter, Depends, Request, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime, timezone
import logging

from app.db.database import get_db
from app.models.patient import Patient
from app.models.message import Message
from app.core.config import settings
from app.services.whatsapp_service import wa_service

router = APIRouter()
logger = logging.getLogger(__name__)


class WhatsAppMessageRequest(BaseModel):
    to: str
    message: str


class WhatsAppTemplateRequest(BaseModel):
    to: str
    template_name: str
    language: str = "en_US"


class MessageStatusResponse(BaseModel):
    wa_message_id: str
    status: str
    timestamp: datetime
    recipient_id: Optional[str] = None
    error_code: Optional[str] = None
    error_message: Optional[str] = None


class StatusListResponse(BaseModel):
    total: int
    statuses: List[MessageStatusResponse]


@router.get("")
@router.get("/whatsapp")
@router.get("/webhook")
def verify_webhook(
    hub_mode: Optional[str] = Query(None, alias="hub.mode"),
    hub_challenge: Optional[str] = Query(None, alias="hub.challenge"),
    hub_verify_token: Optional[str] = Query(None, alias="hub.verify_token"),
):
    logger.info(f"Webhook verification: mode={hub_mode}, token={hub_verify_token}")
    if hub_mode == "subscribe" and hub_verify_token == settings.WHATSAPP_VERIFY_TOKEN:
        logger.info("Webhook verified successfully")
        return int(hub_challenge) if hub_challenge else {"challenge": "ok"}
    raise HTTPException(status_code=403, detail="Verification failed")


@router.post("/whatsapp")
@router.post("/webhook")
async def receive_whatsapp_webhook(
    request: Request,
    db: Session = Depends(get_db)
):
    body = await request.json()
    logger.info(f"Received WhatsApp webhook: {body}")

    try:
        entry = body.get("entry", [])[0]
        changes = entry.get("changes", [])[0]
        value = changes.get("value", {})

        # Processar mensagens recebidas (do usuário)
        messages = value.get("messages", [])
        for msg in messages:
            wa_from = msg.get("from")
            wa_msg_id = msg.get("id")
            msg_type = msg.get("type")

            content = ""
            if msg_type == "text":
                content = msg.get("text", {}).get("body", "")
            elif msg_type == "interactive":
                button_reply = msg.get("interactive", {}).get("button_reply", {})
                content = button_reply.get("title", "")

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

            db_message = Message(
                patient_id=patient.id,
                content=content,
                message_type=msg_type,
                source="whatsapp",
                wa_message_id=wa_msg_id,
                wa_from=wa_from,
                is_delivered=True
            )
            db.add(db_message)
            db.commit()

            logger.info(f"Message saved from {wa_from}")

            # --- INTEGRAÇÃO IA RAG ---
            # Gerar resposta inteligente
            try:
                from app.services.ai_service import ai_service
                ai_response = await ai_service.get_ai_response(content)
                
                # Salvar resposta do Bot no banco
                bot_message = Message(
                    patient_id=patient.id,
                    content=ai_response,
                    message_type="text",
                    source="bot",
                    wa_from=settings.WHATSAPP_PHONE_NUMBER_ID, # Remetente é o bot
                    is_delivered=False
                )
                db.add(bot_message)
                db.commit()
                logger.info(f"AI response generated and saved for {wa_from}")

                # Tentar enviar de volta via WhatsApp (Bot -> User)
                try:
                    send_result = await wa_service.send_message(to=wa_from, message=ai_response)
                    
                    # Capturar ID da mensagem enviada pela Meta
                    if send_result and "messages" in send_result:
                        wa_msg_id_sent = send_result["messages"][0].get("id")
                        bot_message.wa_message_id = wa_msg_id_sent
                        db.commit()
                        logger.info(f"AI response successfully sent and ID tracked: {wa_msg_id_sent}")
                    
                except Exception as e:
                    import json
                    error_msg = str(e)
                    if hasattr(e, "response"):
                        try:
                            error_data = e.response.json()
                            error_msg = error_data.get("error", {}).get("message", error_msg)
                        except:
                            error_msg = e.response.text
                    logger.error(f"Failed to send AI response back via WhatsApp: {error_msg}")


            except Exception as e:
                logger.error(f"Error generating AI response: {e}")
            # --------------------------

        # Processar status de entrega (sent, delivered, read, failed)
        statuses = value.get("statuses", [])
        for st in statuses:
            wa_msg_id = st.get("id")
            status_val = st.get("status")
            timestamp = st.get("timestamp")
            recipient = st.get("recipient_id")
            errors = st.get("errors", [])

            logger.info(f"Message status update: {wa_msg_id} -> {status_val}")

            # Atualizar a mensagem no banco se existir
            if wa_msg_id:
                message = db.query(Message).filter(Message.wa_message_id == wa_msg_id).first()
                if message:
                    if status_val == "delivered":
                        message.is_delivered = True
                    elif status_val == "read":
                        message.is_read = True
                    elif status_val == "failed":
                        message.is_delivered = False
                    db.commit()
                    logger.info(f"Updated message {wa_msg_id} status to {status_val}")

        return {"status": "ok"}
    except Exception as e:
        logger.error(f"Error processing webhook: {e}")
        return {"status": "error", "detail": str(e)}


@router.get("/status", response_model=StatusListResponse)
def get_message_statuses(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """Consultar status das mensagens"""
    messages = db.query(Message).filter(
        Message.wa_message_id.isnot(None)
    ).order_by(Message.created_at.desc()).offset(skip).limit(limit).all()

    statuses = []
    for msg in messages:
        status_val = "unknown"
        if msg.is_delivered and msg.is_read:
            status_val = "read"
        elif msg.is_delivered:
            status_val = "delivered"
        elif msg.wa_message_id:
            status_val = "sent"
        
        statuses.append(MessageStatusResponse(
            wa_message_id=msg.wa_message_id or "",
            status=status_val,
            timestamp=msg.created_at.replace(tzinfo=timezone.utc),
            recipient_id=msg.wa_from
        ))

    return {"total": len(statuses), "statuses": statuses}


@router.post("/send")
async def send_whatsapp_message(
    request: WhatsAppMessageRequest,
    db: Session = Depends(get_db)
):
    logger.info(f"Sending WhatsApp message to {request.to}: {request.message}")

    try:
        # Normalizar número (remover não-dígitos)
        import re
        to_clean = re.sub(r"\D", "", request.to)
        
        result = await wa_service.send_message(to_clean, request.message)

        
        # Salvar mensagem no banco
        patient = db.query(Patient).filter(Patient.whatsapp == request.to).first()
        if not patient:
            # Criar paciente básico se não existir
            patient = Patient(
                name=f"WA: {request.to[-4:]}",
                phone=request.to,
                whatsapp=request.to
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            logger.info(f"Auto-created patient for {request.to}")

        wa_msg_id = result.get("messages", [{}])[0].get("id") if result.get("messages") else None
        msg = Message(
            patient_id=patient.id,
            content=request.message,
            message_type="text",
            source="app",
            wa_message_id=wa_msg_id,
            wa_from=request.to,
            is_delivered=False
        )
        db.add(msg)
        db.commit()
        
        return {"status": "success", "data": result}
    except Exception as e:
        import json
        error_msg = str(e)
        status_code = 500
        
        if hasattr(e, "response"):
            status_code = e.response.status_code
            try:
                error_data = e.response.json()
                meta_error = error_data.get("error", {})
                error_msg = f"Meta API Error: {meta_error.get('message', error_msg)} (Code: {meta_error.get('code')})"
            except:
                error_msg = f"Meta API Error: {e.response.text}"
        
        logger.error(f"Error sending message: {error_msg}")
        raise HTTPException(status_code=status_code, detail=error_msg)



@router.post("/send-template")
async def send_whatsapp_template(
    request: WhatsAppTemplateRequest,
    db: Session = Depends(get_db)
):
    logger.info(f"Sending WhatsApp template to {request.to}: {request.template_name}")

    try:
        result = await wa_service.send_template(request.to, request.template_name, request.language)
        
        logger.info(f"Result from WhatsApp API: {result}")
        
        # Salvar mensagem no banco
        patient = db.query(Patient).filter(Patient.whatsapp == request.to).first()
        logger.info(f"Patient found: {patient}")
        
        if patient:
            messages_data = result.get("messages", [])
            logger.info(f"Messages data: {messages_data}")
            wa_msg_id = messages_data[0].get("id") if messages_data else None
            logger.info(f"wa_msg_id: {wa_msg_id}")
            
            msg = Message(
                patient_id=patient.id,
                content=f"Template: {request.template_name}",
                message_type="template",
                source="app",
                wa_message_id=wa_msg_id,
                wa_from=request.to,
                is_delivered=False
            )
            db.add(msg)
            db.commit()
            logger.info(f"Message saved to database")
        
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error sending template: {e}")
        raise HTTPException(status_code=500, detail=str(e))