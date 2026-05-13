from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime

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
    query = db.query(Appointment)
    
    # Se for paciente, filtra apenas os seus agendamentos
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
        if patient:
            query = query.filter(Appointment.patient_id == patient.id)
        else:
            # Se não encontrar o registro de paciente, retorna lista vazia
            return {"total": 0, "appointments": []}
    
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
    
    return {"total": total, "appointments": appointments}


@router.get("/{appointment_id}", response_model=AppointmentResponse)
def get_appointment(
    appointment_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
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
        db_appointment.completed_at = datetime.utcnow()
    
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