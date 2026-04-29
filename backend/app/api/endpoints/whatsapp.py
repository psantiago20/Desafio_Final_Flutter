from fastapi import APIRouter, Depends, Request, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime, timezone
import logging
import json

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

class ChatDirectRequest(BaseModel):
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
    content: Optional[str] = None
    meta: Optional[str] = None


class StatusListResponse(BaseModel):
    total: int
    statuses: List[MessageStatusResponse]


@router.get("")
@router.get("/whatsapp")
async def verify_webhook(request: Request):
    """Verificar webhook da Meta"""
    params = dict(request.query_params)
    mode = params.get("hub.mode")
    token = params.get("hub.verify_token")
    challenge = params.get("hub.challenge")

    if mode and token:
        if mode == "subscribe" and token == settings.WHATSAPP_VERIFY_TOKEN:
            logger.info("Webhook verified successfully")
            return int(challenge)
        else:
            logger.warning("Webhook verification failed")
            raise HTTPException(status_code=403, detail="Verification token mismatch")
    
    return {"status": "ok"}


@router.post("")
@router.post("/whatsapp")
async def handle_webhook(request: Request, db: Session = Depends(get_db)):
    """Receber eventos do WhatsApp"""
    try:
        body = await request.json()
        logger.info(f"Webhook received: {body}")

        entry = body.get("entry", [])
        if not entry:
            return {"status": "ok"}

        changes = entry[0].get("changes", [])
        if not changes:
            return {"status": "ok"}

        value = changes[0].get("value", {})
        
        # Processar mensagens recebidas
        messages = value.get("messages", [])
        for msg_data in messages:
            wa_from = msg_data.get("from")
            wa_id = msg_data.get("id")
            timestamp = msg_data.get("timestamp")
            
            text_data = msg_data.get("text", {})
            content = text_data.get("body", "")

            # Salvar no banco
            patient = db.query(Patient).filter(Patient.whatsapp == wa_from).first()
            if not patient:
                # Criar paciente básico se não existir
                patient = Patient(
                    name=f"WhatsApp User {wa_from[-4:]}",
                    phone=wa_from,
                    whatsapp=wa_from
                )
                db.add(patient)
                db.commit()
                db.refresh(patient)

            # Criar mensagem
            message = Message(
                patient_id=patient.id,
                content=content,
                message_type="text",
                source="whatsapp",
                wa_message_id=wa_id,
                wa_from=wa_from
            )
            db.add(message)
            db.commit()
            logger.info(f"Message saved from {wa_from}: {content}")

            # --------------------------
            # INTEGRAÇÃO RAG / RESPOSTA AUTOMÁTICA
            # --------------------------
            try:
                from app.services.ai_service import ai_service
                
                # Gerar resposta usando RAG
                ai_response = await ai_service.generate_response(content, patient_id=patient.id)
                
                # Salvar resposta da IA no banco
                bot_message = Message(
                    patient_id=patient.id,
                    content=ai_response,
                    message_type="text",
                    source="ai",
                    wa_from="system"
                )
                db.add(bot_message)
                db.commit()
                
                # Enviar de volta pelo WhatsApp
                try:
                    send_result = await wa_service.send_message(to=wa_from, message=ai_response)
                    
                    # Capturar ID da mensagem enviada pela Meta
                    if send_result and "messages" in send_result:
                        wa_msg_id_sent = send_result["messages"][0].get("id")
                        bot_message.wa_message_id = wa_msg_id_sent
                        db.commit()
                        logger.info(f"AI response successfully sent and ID tracked: {wa_msg_id_sent}")
                    
                except Exception as e:
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
                        if errors:
                            meta_data = {}
                            if message.meta:
                                try:
                                    meta_data = json.loads(message.meta)
                                except:
                                    pass
                            meta_data["errors"] = errors
                            message.meta = json.dumps(meta_data)
                            logger.error(f"Message {wa_msg_id} failed with errors: {errors}")
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
            # Check meta for errors to know if it failed
            meta_data = {}
            if msg.meta:
                try:
                    meta_data = json.loads(msg.meta)
                except:
                    pass
            if "errors" in meta_data:
                status_val = "failed"
            else:
                status_val = "sent"
        
        error_code = None
        error_message = None
        if msg.meta:
            try:
                meta_data = json.loads(msg.meta)
                
                # Check for Webhook errors (plural)
                errors_list = meta_data.get("errors", [])
                if errors_list:
                    error_code = str(errors_list[0].get("code", ""))
                    error_message = errors_list[0].get("message", "Unknown error")
                    error_details = errors_list[0].get("error_data", {}).get("details", "")
                    if error_details:
                        error_message += f" - {error_details}"
                
                # Check for Direct API errors (singular)
                elif "error" in meta_data:
                    err = meta_data["error"]
                    error_code = str(err.get("code", ""))
                    error_message = err.get("message", "Unknown API error")
                    if "error_data" in err:
                        details = err["error_data"].get("details", "")
                        if details:
                            error_message += f" - {details}"
                
                # If we have any error, force status to failed
                if (errors_list or "error" in meta_data) and status_val != "failed":
                    status_val = "failed"
            except:
                pass

        statuses.append(MessageStatusResponse(
            wa_message_id=msg.wa_message_id or "",
            status=status_val,
            timestamp=msg.created_at.replace(tzinfo=timezone.utc),
            recipient_id=msg.wa_from,
            error_code=error_code,
            error_message=error_message,
            content=msg.content,
            meta=msg.meta
        ))

    return {"total": len(statuses), "statuses": statuses}

@router.get("/failed-messages")
def get_failed_messages(
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db)
):
    """Consultar mensagens que falharam com detalhes do erro"""
    from sqlalchemy import or_
    messages = db.query(Message).filter(
        Message.wa_message_id.isnot(None),
        or_(
            Message.meta.like('%"error"%'),
            Message.meta.like('%"errors"%')
        )
    ).order_by(Message.created_at.desc()).offset(skip).limit(limit).all()

    failed = []
    for msg in messages:
        error_code = None
        error_message = None
        if msg.meta:
            try:
                meta_data = json.loads(msg.meta)
                errors = meta_data.get("errors", [])
                if errors:
                    error_code = str(errors[0].get("code", ""))
                    error_message = errors[0].get("message", "Unknown error")
                    error_details = errors[0].get("error_data", {}).get("details", "")
                    if error_details:
                        error_message += f" - {error_details}"
            except:
                pass
        
        failed.append({
            "wa_message_id": msg.wa_message_id,
            "content": msg.content,
            "to": msg.wa_from,
            "error_code": error_code,
            "error_message": error_message,
            "timestamp": msg.created_at.replace(tzinfo=timezone.utc)
        })

    return {"total": len(failed), "failed_messages": failed}



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

        wa_msg_id = result.get("messages", [{}])[0].get("id") if result.get("messages") else None
        msg = Message(
            patient_id=patient.id,
            content=request.message,
            message_type="text",
            source="app",
            wa_message_id=wa_msg_id,
            wa_from=request.to,
            is_delivered=False,
            meta=json.dumps(result)
        )
        db.add(msg)
        db.commit()
        
        return {"status": "success", "data": result}
    except Exception as e:
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
                is_delivered=False,
                meta=json.dumps(result)
            )
            db.add(msg)
            db.commit()
            logger.info(f"Template message saved in DB")
        
        return {"status": "success", "data": result}
    except Exception as e:
        logger.error(f"Error sending template: {e}")
        raise HTTPException(status_code=500, detail=str(e))