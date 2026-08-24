from fastapi import APIRouter, Depends, Request, HTTPException, status, Query, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Optional, List
from pydantic import BaseModel
from datetime import datetime, timezone
import logging
import json

from app.db.database import get_db, SessionLocal
from app.models.patient import Patient
from app.models.message import Message
from app.core.config import settings
from app.services.whatsapp_service import wa_service
from app.services.transcription_service import transcription_service
from app.utils.phone_utils import find_patient_by_messaging_phone, ensure_canonical_whatsapp

router = APIRouter()
logger = logging.getLogger(__name__)

async def process_rag_background(wa_from: str, content: str, phone_number_id: str, patient_id: int):
    """Background task to decouple LangChain/RAG processing from Meta Webhook."""
    db = SessionLocal()
    try:
        from app.services.rag_service import rag_service
        from app.services.doctor_mapper import doctor_mapper
        from app.services.whatsapp_service import wa_service
        from app.services.content_moderation_service import content_moderation_service

        # --- MODERAÇÃO DE SEGURANÇA ---
        is_safe, reason = await content_moderation_service.check_text_safety(content)
        if not is_safe:
            ai_response = f"⚠️ Mensagem Bloqueada por Segurança: Identificamos conteúdo inadequado ({reason}) que viola nossas diretrizes de segurança."
            
            # Encontrar e mascarar a mensagem de entrada inadequada no banco para não manter conteúdo ilícito
            unsafe_msg = db.query(Message).filter(
                Message.patient_id == patient_id,
                Message.content == content,
                Message.source == "whatsapp"
            ).order_by(Message.created_at.desc()).first()
            
            if unsafe_msg:
                unsafe_msg.content = "[MENSAGEM BLOQUEADA PELO FILTRO DE SEGURANÇA]"
                db.add(unsafe_msg)
            
            bot_message = Message(
                patient_id=patient_id,
                content=ai_response,
                message_type="text",
                source="ai",
                wa_from="system"
            )
            db.add(bot_message)
            db.commit()

            try:
                await wa_service.send_message(to=wa_from, message=ai_response)
            except Exception as send_err:
                logger.error(f"Failed to send block alert: {send_err}")
            return
        # -----------------------------

        doctor = doctor_mapper.get_doctor_by_phone_number_id(phone_number_id, db)
        wa_to = doctor.whatsapp if doctor else None

        # Buscar paciente no banco
        from app.models.patient import Patient
        patient = db.query(Patient).filter(Patient.id == patient_id).first()
        patient_name = patient.name if patient else "Paciente"

        ai_response = await rag_service.get_rag_response(content, wa_to, db, wa_from=wa_from, user_name=patient_name, patient_id=patient_id)        
        bot_message = Message(
            patient_id=patient_id,
            content=ai_response,
            message_type="text",
            source="ai",
            wa_from="system"
        )
        db.add(bot_message)
        db.commit()

        try:
            send_result = await wa_service.send_message(to=wa_from, message=ai_response)
            if send_result and "messages" in send_result:
                wa_msg_id_sent = send_result["messages"][0].get("id")
                bot_message.wa_message_id = wa_msg_id_sent
                db.commit()
                logger.info(f"RAG response successfully sent and ID tracked: {wa_msg_id_sent}")
        except Exception as e:
            error_msg = str(e)
            if hasattr(e, "response"):
                try:
                    error_data = e.response.json()
                    error_msg = error_data.get("error", {}).get("message", error_msg)
                except:
                    error_msg = getattr(e, "response").text
            logger.error(f"Failed to send RAG response back via WhatsApp: {error_msg}")
    except Exception as e:
        logger.error(f"Error generating RAG response: {e}")
    finally:
        db.close()


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
async def handle_webhook(request: Request, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    """Receber eventos do WhatsApp"""
    try:
        body = await request.json()
        if settings.DEBUG:
            logger.info(f"Webhook received: {body}")
        else:
            logger.info("Webhook received (Payload hidden in production)")

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
            
            # Detectar tipo de mensagem
            msg_type = msg_data.get("type")
            content = ""

            if msg_type == "text":
                text_data = msg_data.get("text", {})
                content = text_data.get("body", "")
            elif msg_type == "audio":
                audio_data = msg_data.get("audio", {})
                media_id = audio_data.get("id")
                logger.info(f"Recebido áudio do WhatsApp. Media ID: {media_id}")
                
                try:
                    # Fluxo de áudio: baixar e transcrever
                    media_url = await wa_service.get_media_url(media_id)
                    audio_bytes = await wa_service.download_media(media_url)
                    content = await transcription_service.transcribe_audio(audio_bytes)
                    if content.startswith("[Silêncio") or content.startswith("[Áudio muito curto"):
                        logger.warning(f"Ignorando áudio silêncio/curto do WhatsApp: {wa_from}")
                        continue # Pula o processamento dessa mensagem
                    logger.info(f"Áudio transcrito com sucesso: {content[:50]}...")
                except Exception as e:
                    logger.error(f"Erro ao processar áudio do WhatsApp: {e}")
                    content = "[Erro ao processar áudio]"
            elif msg_type in ("image", "document"):
                media_data = msg_data.get(msg_type, {})
                media_id = media_data.get("id")
                mime_type = media_data.get("mime_type")
                filename = media_data.get("filename") or f"whatsapp_{media_id}"

                if msg_type == "image" and "." not in filename:
                    filename += ".jpg"
                elif (
                    msg_type == "document"
                    and mime_type == "application/pdf"
                    and not filename.lower().endswith(".pdf")
                ):
                    filename += ".pdf"

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
                else:
                    ensure_canonical_whatsapp(db, patient, wa_from)

                try:
                    media_url = await wa_service.get_media_url(media_id)
                    media_bytes = await wa_service.download_media(media_url)
                    from app.api.endpoints.rag import process_exam_file

                    result = await process_exam_file(
                        db=db,
                        content=media_bytes,
                        filename=filename,
                        wa_from=wa_from,
                        mime_type=mime_type,
                        patient=patient,
                        source="whatsapp",
                        message_type=msg_type,
                    )
                    reply = result.get("message") or "Recebi seu exame!"
                    await wa_service.send_message(to=wa_from, message=reply)
                except Exception as e:
                    logger.error(f"Erro ao processar exame do WhatsApp: {e}", exc_info=True)
                    await wa_service.send_message(
                        to=wa_from,
                        message="Recebi o arquivo, mas nao consegui processar o exame agora. Pode tentar enviar novamente?"
                    )
                continue
            else:
                logger.warning(f"Tipo de mensagem não suportado: {msg_type}")
                continue # Pula outros tipos por enquanto

            if not content:
                logger.warning("Mensagem sem conteúdo (texto ou áudio). Ignorando.")
                continue

            # Salvar no banco (mesmo paciente do app se o telefone cadastrado bater)
            patient = find_patient_by_messaging_phone(db, wa_from)
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
            else:
                ensure_canonical_whatsapp(db, patient, wa_from)
            # Criar mensagem
            message = Message(
                patient_id=patient.id,
                content=content,
                message_type=msg_type,
                source="whatsapp",
                wa_message_id=wa_id,
                wa_from=wa_from
            )
            db.add(message)
            db.commit()
            if settings.DEBUG:
                logger.info(f"Message saved from {wa_from}: {content}")
            else:
                logger.info(f"Message saved from {wa_from} (Content hidden)")

            logger.info(f"Message saved from {wa_from}")

            # --- INTEGRAÇÃO RAG (Background Task) ---
            phone_number_id = value.get("metadata", {}).get("phone_number_id", "")
            background_tasks.add_task(process_rag_background, wa_from, content, phone_number_id, patient.id)
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
        patient = find_patient_by_messaging_phone(db, request.to)
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
        else:
            ensure_canonical_whatsapp(db, patient, to_clean)

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
        patient = find_patient_by_messaging_phone(db, request.to)
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

class ChatDirectRequestV2(BaseModel):
    to: str
    message: str
    wa_to: Optional[str] = None
    doctor_id: Optional[int] = None
    new_session: bool = False  # True quando o Flutter detecta início de nova sessão (ex: rebuild da tela)


@router.post("/chat-direct")
async def chat_direct(
    request: ChatDirectRequestV2,
    db: Session = Depends(get_db)
):
    """Endpoint for testing the RAG bot directly from the frontend, bypassing WhatsApp Meta API."""
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Direct chat is only available in development/debug mode."
        )
    if settings.DEBUG:
        logger.info(f"Direct chat received from {request.to}: {request.message}")
    
    wa_from = request.to
    content = request.message
    doctor_id = request.doctor_id
    
    # Same logic as webhook for saving the user's message
    patient = find_patient_by_messaging_phone(db, wa_from)

    if not patient:
        patient = Patient(
            name=f"App User {wa_from[-4:]}",
            phone=wa_from,
            whatsapp=wa_from
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)
    else:
        ensure_canonical_whatsapp(db, patient, wa_from)

    # --- MODERAÇÃO DE SEGURANÇA ---
    from app.services.content_moderation_service import content_moderation_service
    is_safe, reason = await content_moderation_service.check_text_safety(content)
    if not is_safe:
        ai_response = f"⚠️ Mensagem Bloqueada por Segurança: Identificamos conteúdo inadequado ({reason}) que viola nossas diretrizes de segurança."
        
        # Salva o log mascarado no banco
        db.add(Message(
            patient_id=patient.id,
            content="[MENSAGEM BLOQUEADA PELO FILTRO DE SEGURANÇA]",
            message_type="text",
            source="whatsapp",
            wa_message_id=f"simulated_{datetime.now().timestamp()}",
            wa_from=wa_from,
            is_delivered=True,
            is_read=True
        ))
        db.add(Message(
            patient_id=patient.id,
            content=ai_response,
            message_type="text",
            source="bot",
            wa_from=settings.WHATSAPP_PHONE_NUMBER_ID or "BOT",
            wa_message_id=f"simulated_resp_{datetime.now().timestamp()}",
            is_delivered=True,
            is_read=True
        ))
        db.commit()

        return {
            "status": "blocked",
            "response": ai_response
        }
    # -----------------------------

    db_message = Message(
        patient_id=patient.id,
        content=content,
        message_type="text",
        source="whatsapp", # Pretend it's from whatsapp so it shows up similarly
        wa_message_id=f"simulated_{datetime.now().timestamp()}",
        wa_from=wa_from,
        is_delivered=True,
        is_read=True
    )
    db.add(db_message)
    db.commit()

    # Get RAG response
    try:
        from app.services.rag_service import rag_service
        # Se wa_to não vier no request, podemos usar o doctor_id para buscar o telefone se necessário,
        # ou passar None para usar o médico padrão (0)
        wa_to_effective = request.wa_to

        # --- RESET DE SESSÃO ---
        # Quando o Flutter reconstrói a tela (ex: reload), envia new_session=True.
        # Isso limpa o histórico do LangGraph (MemorySaver) e do ConversationManager,
        # garantindo que a IA saiba que é uma conversa completamente nova.
        if request.new_session:
            rag_service.clear_conversation(wa_from)
            logger.info(f"[chat-direct] new_session=True: estado de {wa_from} limpo antes de processar.")
        
        # Pipeline RAG: Passa wa_from e wa_to para gerenciamento de estado e contexto do médico
        ai_response = await rag_service.get_rag_response(
            content, wa_to=wa_to_effective, db=db, wa_from=wa_from, source="app", patient_id=patient.id
        )
        
        bot_message = Message(
            patient_id=patient.id,
            content=ai_response,
            message_type="text",
            source="bot",
            wa_from=settings.WHATSAPP_PHONE_NUMBER_ID or "BOT",
            wa_message_id=f"simulated_resp_{datetime.now().timestamp()}",
            is_delivered=True,
            is_read=True
        )
        db.add(bot_message)
        db.commit()
        
        return {
            "status": "success", 
            "response": ai_response
        }
    except Exception as e:
        logger.error(f"Error generating RAG response in direct chat: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/clear-conversation")
def clear_conversation(
    wa_from: str = Query(..., description="Número WhatsApp do paciente")
):
    """Limpa o estado da conversa (para testes — simula nova conversa)."""
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Debug endpoints are disabled in production."
        )
    from app.services.rag_service import rag_service
    rag_service.clear_conversation(wa_from)
    return {"status": "success", "message": f"Estado da conversa de {wa_from} limpo"}


@router.get("/conversation-state")
def get_conversation_state(
    wa_from: str = Query(..., description="Número WhatsApp do paciente")
):
    """Retorna o estado da conversa de um número (para debug)."""
    if not settings.DEBUG:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="Debug endpoints are disabled in production."
        )
    from app.services.rag_service import rag_service
    state = rag_service.get_conversation_state(wa_from)
    return {"wa_from": wa_from, "state": state}
