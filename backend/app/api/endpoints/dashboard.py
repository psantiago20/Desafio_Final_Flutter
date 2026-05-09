from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional

from app.db.database import get_db
from app.models.patient import Patient
from app.models.appointment import Appointment
from app.models.message import Message
from app.models.service import Service
from app.api.endpoints.auth import get_current_user
from app.models.user import User
from pydantic import BaseModel
from app.core.config import settings

router = APIRouter()


class DashboardStats(BaseModel):
    total_patients: int
    total_appointments: int
    pending_appointments: int
    completed_appointments: int
    cancelled_appointments: int
    unread_messages: int
    total_services: int
    revenue_today: float
    revenue_week: float
    revenue_month: float
    no_show_rate: float
    appointment_type_breakdown: dict


@router.get("/stats", response_model=DashboardStats)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Se for paciente, as estatísticas são personalizadas
    if current_user.role == "patient":
        # Encontrar o registro de paciente vinculado ao usuário (pelo email)
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
        
        if not patient:
            return {
                "total_patients": 0, "total_appointments": 0, "pending_appointments": 0,
                "completed_appointments": 0, "cancelled_appointments": 0,
                "unread_messages": 0, "total_services": 0, "revenue_today": 0,
                "revenue_week": 0, "revenue_month": 0, "no_show_rate": 0,
                "appointment_type_breakdown": {}
            }
        
        total_appointments = db.query(Appointment).filter(Appointment.patient_id == patient.id).count()
        pending_appointments = db.query(Appointment).filter(Appointment.patient_id == patient.id, Appointment.status == "pending").count()
        completed_appointments = db.query(Appointment).filter(Appointment.patient_id == patient.id, Appointment.status == "completed").count()
        cancelled_appointments = db.query(Appointment).filter(Appointment.patient_id == patient.id, Appointment.status == "cancelled").count()
        
        unread_messages = db.query(Message).filter(Message.patient_id == patient.id, Message.is_read == False).count()
        
        return {
            "total_patients": 1,
            "total_appointments": total_appointments,
            "pending_appointments": pending_appointments,
            "completed_appointments": completed_appointments,
            "cancelled_appointments": cancelled_appointments,
            "unread_messages": unread_messages,
            "total_services": 0,
            "revenue_today": 0,
            "revenue_week": 0,
            "revenue_month": 0,
            "no_show_rate": 0,
            "appointment_type_breakdown": {}
        }

    # Caso contrário (Admin/Médico), retorna estatísticas globais
    total_patients = db.query(Patient).filter(Patient.is_active == True).count()
    
    total_appointments = db.query(Appointment).count()
    pending_appointments = db.query(Appointment).filter(Appointment.status == "pending").count()
    completed_appointments = db.query(Appointment).filter(Appointment.status == "completed").count()
    cancelled_appointments = db.query(Appointment).filter(Appointment.status == "cancelled").count()
    
    unread_messages = db.query(Message).filter(Message.is_read == False).count()
    
    total_services = db.query(Service).count()
    
    today = datetime.utcnow().date()
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)
    
    revenue_today = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(today, datetime.min.time()),
        Appointment.paid == True
    ).scalar() or 0
    
    revenue_week = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(week_ago, datetime.min.time()),
        Appointment.paid == True
    ).scalar() or 0
    
    revenue_month = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(month_ago, datetime.min.time()),
        Appointment.paid == True
    ).scalar() or 0
    
    no_show_count = db.query(Appointment).filter(Appointment.status == "no_show").count()
    no_show_rate = (no_show_count / total_appointments * 100) if total_appointments > 0 else 0
    
    type_breakdown = {}
    types = db.query(Appointment.type, func.count(Appointment.id)).group_by(Appointment.type).all()
    for apt_type, count in types:
        type_breakdown[apt_type] = count
    
    return {
        "total_patients": total_patients,
        "total_appointments": total_appointments,
        "pending_appointments": pending_appointments,
        "completed_appointments": completed_appointments,
        "cancelled_appointments": cancelled_appointments,
        "unread_messages": unread_messages,
        "total_services": total_services,
        "revenue_today": float(revenue_today),
        "revenue_week": float(revenue_week),
        "revenue_month": float(revenue_month),
        "no_show_rate": round(no_show_rate, 2),
        "appointment_type_breakdown": type_breakdown
    }


@router.get("/appointments/today")
def get_today_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = datetime.utcnow().date()
    appointments = db.query(Appointment).filter(
        func.date(Appointment.appointment_date) == today
    ).order_by(Appointment.appointment_date).all()
    return appointments


@router.get("/appointments/upcoming")
def get_upcoming_appointments(
    limit: int = 5,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    now = datetime.utcnow()
    appointments = db.query(Appointment).filter(
        Appointment.appointment_date > now,
        Appointment.status == "pending"
    ).order_by(Appointment.appointment_date).limit(limit).all()
    return appointments


@router.get("/system-status")
def get_system_status():
    # Verifica se as credenciais basicas estao configuradas
    whatsapp_status = "Conectado" if settings.WHATSAPP_PHONE_NUMBER_ID and settings.WHATSAPP_ACCESS_TOKEN else "Desconectado"
    
    # Obtem a IA configurada baseada no AIService
    if settings.NVIDIA_API_KEY:
        ia_engine = "Nvidia (Llama 3.1)"
    elif settings.OLLAMA_MODEL:
        ia_engine = f"Ollama ({settings.OLLAMA_MODEL})"
    else:
        ia_engine = "Nenhuma IA configurada"
    
    return {
        "whatsapp_status": whatsapp_status,
        "ia_engine": ia_engine
    }