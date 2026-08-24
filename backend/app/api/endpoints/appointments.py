from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
import asyncio

from app.db.database import get_db
from app.models.appointment import Appointment
from app.services.fcm_service import fcm_service
from app.models.patient import Patient
from app.schemas.appointment import (
    AppointmentCreate, AppointmentUpdate, AppointmentResponse,
    AppointmentStatusUpdate, AppointmentListResponse
)
from app.api.endpoints.auth import get_current_user
from app.models.user import User
from app.models.message import Message, MessageType, MessageSource
from app.services.prescription_service import prescription_service

router = APIRouter()


@router.get("", response_model=AppointmentListResponse)
def list_appointments(
    skip: int = 0,
    limit: int = 100,
    patient_id: Optional[int] = None,
    doctor_id: Optional[int] = None,
    status_filter: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy.orm import joinedload
    query = db.query(Appointment).options(
        joinedload(Appointment.doctor),
        joinedload(Appointment.medico),
        joinedload(Appointment.patient)
    )
    
    # Se for paciente, filtra apenas os seus agendamentos
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
        if patient:
            query = query.filter(Appointment.patient_id == patient.id)
        else:
            return {"total": 0, "appointments": []}
    
    # Se for médico e não especificou um doctor_id no filtro, filtra apenas os dele
    # EXCETO se ele estiver buscando o histórico de um paciente específico
    if current_user.role == "doctor" and not doctor_id and not patient_id:
        query = query.filter(Appointment.doctor_id == current_user.id)
    
    if patient_id:
        query = query.filter(Appointment.patient_id == patient_id)
    if doctor_id:
        query = query.filter(Appointment.doctor_id == doctor_id)
    if status_filter:
        query = query.filter(Appointment.status == status_filter)
    if date_from:
        query = query.filter(Appointment.appointment_date >= date_from)
    if date_to:
        query = query.filter(Appointment.appointment_date <= date_to)
    
    total = query.count()
    appointments = query.order_by(Appointment.appointment_date.desc()).offset(skip).limit(limit).all()
    
    # Adicionar nomes dinamicamente (Pydantic fará o resto se os atributos existirem)
    for app in appointments:
        app.doctor_name = app.doctor.full_name if app.doctor else f"Médico {app.doctor_id}"
        app.medico_name = app.medico.nome_completo if app.medico else app.doctor_name
        app.patient_name = app.patient.name if app.patient else f"Paciente #{app.patient_id}"
        # Hack para o front-end antigo: já envia o tipo traduzido
        if app.type == "consultation":
            app.type = "Consulta"
        elif app.type == "exam":
            app.type = "Exame"
        elif app.type == "return":
            app.type = "Retorno"
    
    return {"total": total, "appointments": appointments}


@router.get("/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy.orm import joinedload
    appointment = db.query(Appointment).options(
        joinedload(Appointment.doctor),
        joinedload(Appointment.medico),
        joinedload(Appointment.patient)
    ).filter(Appointment.id == appointment_id).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.doctor_name = appointment.doctor.full_name if appointment.doctor else f"Médico {appointment.doctor_id}"
    appointment.medico_name = appointment.medico.nome_completo if appointment.medico else appointment.doctor_name
    appointment.patient_name = appointment.patient.name if appointment.patient else f"Paciente #{appointment.patient_id}"
    
    if appointment.type == "consultation":
        appointment.type = "Consulta"
    elif appointment.type == "exam":
        appointment.type = "Exame"
    elif appointment.type == "return":
        appointment.type = "Retorno"
    
    return appointment


@router.post("", response_model=AppointmentResponse, status_code=status.HTTP_201_CREATED)
def create_appointment(
    appointment: AppointmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    patient = db.query(Patient).filter(Patient.id == appointment.patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    doctor = db.query(User).filter(User.id == appointment.doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    
    db_appointment = Appointment(**appointment.model_dump())
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    # Send FCM notification to doctor
    if doctor.fcm_token:
        patient_name = patient.name or "A patient"
        appt_date_str = db_appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
        fcm_service.send_notification(
            token=doctor.fcm_token,
            title="New Appointment Scheduled",
            body=f"{patient_name} scheduled an appointment for {appt_date_str}.",
            data={
                "type": "appointment_created",
                "appointment_id": str(db_appointment.id)
            }
        )
        
    return db_appointment


@router.put("/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(
    appointment_id: int,
    appointment: AppointmentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not db_appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    update_data = appointment.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_appointment, key, value)
    
    # Sincronizar sinais vitais com o registro do Paciente para o Dashboard
    vital_signs = ["heart_rate", "blood_pressure", "glucose", "temperature", "weight", "height"]
    if any(sign in update_data for sign in vital_signs):
        patient = db.query(Patient).filter(Patient.id == db_appointment.patient_id).first()
        if patient:
            for sign in vital_signs:
                if sign in update_data:
                    setattr(patient, sign, update_data[sign])
    
    db.commit()
    db.refresh(db_appointment)
    return db_appointment


@router.patch("/{appointment_id}/status", response_model=AppointmentResponse)
def update_appointment_status(
    appointment_id: int,
    status_update: AppointmentStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not db_appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    old_status = db_appointment.status
    db_appointment.status = status_update.status
    if status_update.status == "completed":
        db_appointment.completed_at = datetime.now()
    
    db.commit()
    db.refresh(db_appointment)
    
    # Send FCM notification to doctor if status changed to cancelled
    if status_update.status == "cancelled" and old_status != "cancelled":
        db.refresh(db_appointment.doctor)
        if db_appointment.doctor and db_appointment.doctor.fcm_token:
            patient_name = db_appointment.patient.name if db_appointment.patient else "A patient"
            appt_date_str = db_appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
            fcm_service.send_notification(
                token=db_appointment.doctor.fcm_token,
                title="Appointment Canceled",
                body=f"The appointment with {patient_name} on {appt_date_str} has been canceled.",
                data={
                    "type": "appointment_cancelled",
                    "appointment_id": str(db_appointment.id)
                }
            )
            
    return db_appointment


@router.delete("/{appointment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not db_appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Keep details before deleting to send notification
    doctor = db_appointment.doctor
    patient_name = db_appointment.patient.name if db_appointment.patient else "A patient"
    appt_date_str = db_appointment.appointment_date.strftime("%Y-%m-%d %H:%M")
    appt_id_str = str(db_appointment.id)
    
    db.delete(db_appointment)
    db.commit()
    
    # Send FCM notification to doctor
    if doctor and doctor.fcm_token:
        fcm_service.send_notification(
            token=doctor.fcm_token,
            title="Appointment Deleted",
            body=f"The appointment with {patient_name} on {appt_date_str} has been deleted.",
            data={
                "type": "appointment_deleted",
                "appointment_id": appt_id_str
            }
        )
        
    return None


@router.post("/{appointment_id}/send-prescription", response_model=AppointmentResponse)
async def send_prescription(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    print(f"\n>>> [DEBUG] RECEBIDA REQUISIÇÃO DE ENVIO PARA CONSULTA ID: {appointment_id}")
    from sqlalchemy.orm import joinedload
    db_appointment = db.query(Appointment).options(
        joinedload(Appointment.patient),
        joinedload(Appointment.medico),
        joinedload(Appointment.doctor)
    ).filter(Appointment.id == appointment_id).first()
    
    if not db_appointment:
        print(f">>> [DEBUG] ERRO: Consulta {appointment_id} não encontrada!")
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    print(f">>> [DEBUG] Consulta encontrada. Paciente: {db_appointment.patient.name if db_appointment.patient else 'N/A'}")
    
    # Gerar HTML da prescrição
    html_content = prescription_service.generate_html(
        db_appointment, 
        db_appointment.patient, 
        db_appointment.medico
    )
    
    db_appointment.prescription_html = html_content
    
    # Arquiva a prescrição nas mensagens para manter o histórico caso o médico envie múltiplas
    if db_appointment.prescription:
        # 1. Mensagem para o Histórico Interno (Texto completo da Receita)
        archive_msg = Message(
            patient_id=db_appointment.patient_id,
            sender_id=current_user.id,
            content=db_appointment.prescription,
            message_type=MessageType.TEXT.value,
            source=MessageSource.SYSTEM.value,
            meta="prescription_archive",
            created_at=datetime.now()
        )
        db.add(archive_msg)

        # 2. Mensagem para o Chat (Isis informando o envio)
        isis_notification = Message(
            patient_id=db_appointment.patient_id,
            sender_id=current_user.id, # O médico enviou, mas no chat aparece como aviso do sistema/Isis
            content="📄 Uma nova prescrição foi enviada para você! Acesse a aba 'Prescrições' para visualizar os detalhes e baixar o PDF.",
            message_type=MessageType.TEXT.value,
            source=MessageSource.SYSTEM.value, # Usando SYSTEM pois AI não existe no Enum
            created_at=datetime.now()
        )
        db.add(isis_notification)
        
        # 3. Disparo para WhatsApp (Em segundo plano para não travar o Dashboard)
        from fastapi import BackgroundTasks
        
        async def send_wa_async(phone, msg):
            try:
                from app.services.whatsapp_service import wa_service
                print(f"[WHATSAPP] Enviando em segundo plano para {phone}...")
                await wa_service.send_message(phone, msg)
                print(f"[WHATSAPP] Sucesso no envio para {phone}")
            except Exception as e:
                print(f"[WHATSAPP] Erro no envio em segundo plano: {e}")

        if db_appointment.patient and db_appointment.patient.phone:
            patient_phone = db_appointment.patient.phone
            wa_message = f"Olá {db_appointment.patient.name}, o Dr. {current_user.full_name} acabou de enviar uma nova prescrição para você no portal OmniConnect. Acesse para conferir!"
            # Usamos o asyncio.create_task como "fire and forget" seguro
            asyncio.create_task(send_wa_async(patient_phone, wa_message))

        # Agora podemos limpar o campo de rascunho
        db_appointment.prescription = ""
    
    db.commit()
    db.refresh(db_appointment)
    
    print(f">>> [DEBUG] SUCESSO: Prescrição enviada e arquivada para consulta {appointment_id}")
    return db_appointment

@router.get("/{appointment_id}/prescription/pdf")
def download_prescription_pdf(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from fastapi import Response, HTTPException
    from xhtml2pdf import pisa
    import io

    db_appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    
    if not db_appointment or not db_appointment.prescription_html:
        raise HTTPException(status_code=404, detail="Prescrição não encontrada")
    
    # Gerar PDF a partir do HTML
    pdf_buffer = io.BytesIO()
    pisa_status = pisa.CreatePDF(db_appointment.prescription_html, dest=pdf_buffer)
    
    if pisa_status.err:
        raise HTTPException(status_code=500, detail="Erro ao gerar PDF")
    
    pdf_buffer.seek(0)
    pdf_content = pdf_buffer.getvalue()
    
    return Response(
        content=pdf_content,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f"attachment; filename=Prescricao_{appointment_id}.pdf"
        }
    )