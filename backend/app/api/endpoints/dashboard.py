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
    # Novos campos para Paciente
    heart_rate: Optional[str] = None
    blood_pressure: Optional[str] = None
    glucose: Optional[str] = None
    temperature: Optional[str] = None
    weight: Optional[str] = None
    height: Optional[str] = None
    last_exam_date: Optional[str] = None
    last_prescription_date: Optional[str] = None


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
        
        # Para o paciente, contamos mensagens recebidas (de médicos ou bot)
        # EXCLUÍMOS mensagens de arquivamento (meta='prescription_archive')
        unread_messages = db.query(Message).filter(
            Message.patient_id == patient.id, 
            Message.is_read == False,
            Message.sender_id != patient.user_id,
            Message.meta != 'prescription_archive'
        ).count()
        
        from app.models.exam import Exam
        last_exam = db.query(Exam).filter(Exam.patient_id == patient.id).order_by(Exam.created_at.desc()).first()
        last_exam_date = None
        if last_exam:
            diff = datetime.utcnow() - last_exam.created_at.replace(tzinfo=None)
            if diff.days == 0:
                last_exam_date = "Hoje"
            elif diff.days == 1:
                last_exam_date = "Ontem"
            else:
                last_exam_date = f"Há {diff.days} dias"

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
            "appointment_type_breakdown": {},
            # Dados reais do paciente (None = sem registros, frontend exibe estado vazio)
            "heart_rate": patient.heart_rate or None,
            "blood_pressure": patient.blood_pressure or None,
            "glucose": patient.glucose or None,
            "temperature": getattr(patient, 'temperature', None),
            "weight": getattr(patient, 'weight', None),
            "height": getattr(patient, 'height', None),
            "last_exam_date": last_exam_date,
            "last_prescription_date": None  # Sem módulo de receitas implementado
        }

    # Caso contrário (Admin/Médico), retorna estatísticas globais
    total_patients = db.query(Patient).filter(Patient.is_active == True).count()
    
    total_appointments = db.query(Appointment).count()
    pending_appointments = db.query(Appointment).filter(Appointment.status == "pending").count()
    completed_appointments = db.query(Appointment).filter(Appointment.status == "completed").count()
    cancelled_appointments = db.query(Appointment).filter(Appointment.status == "cancelled").count()
    
    # Para Admin/Médico, contamos mensagens que NÃO foram enviadas por ele
    unread_messages = db.query(Message).filter(
        Message.is_read == False,
        Message.sender_id != current_user.id
    ).count()
    
    total_services = db.query(Service).count()
    
    today = datetime.utcnow().date()
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)
    
    revenue_today = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(today, datetime.min.time()),
        (Appointment.paid == True) | (Appointment.status == "completed")
    ).scalar() or 0
    
    revenue_week = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(week_ago, datetime.min.time()),
        (Appointment.paid == True) | (Appointment.status == "completed")
    ).scalar() or 0
    
    revenue_month = db.query(func.sum(Appointment.price)).filter(
        Appointment.appointment_date >= datetime.combine(month_ago, datetime.min.time()),
        (Appointment.paid == True) | (Appointment.status == "completed")
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
    from sqlalchemy.orm import joinedload
    from datetime import date
    
    query = db.query(Appointment).options(joinedload(Appointment.patient))
    
    # Se for médico, filtra apenas as dele
    if current_user.role == "doctor":
        query = query.filter(Appointment.doctor_id == current_user.id)
    # Se for paciente, filtra apenas as dele
    elif current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
        if patient:
            query = query.filter(Appointment.patient_id == patient.id)
            
    appointments = query.filter(
        func.date(Appointment.appointment_date) == date.today()
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

@router.get("/financial")
def get_financial_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    from sqlalchemy import extract
    
    # Revenue metrics
    today = datetime.utcnow().date()
    month_start = today.replace(day=1)
    year_start = today.replace(month=1, day=1)
    
    # Query builder for revenue
    def get_revenue(start_date=None, end_date=None):
        query = db.query(func.sum(Appointment.price)).filter(
            (Appointment.paid == True) | (Appointment.status == "completed")
        )
        if start_date:
            query = query.filter(Appointment.appointment_date >= datetime.combine(start_date, datetime.min.time()))
        if end_date:
            query = query.filter(Appointment.appointment_date <= datetime.combine(end_date, datetime.max.time()))
            
        if current_user.role == "doctor":
            query = query.filter(Appointment.doctor_id == current_user.id)
            
        return query.scalar() or 0.0

    revenue_today = get_revenue(start_date=today, end_date=today)
    revenue_month = get_revenue(start_date=month_start)
    revenue_year = get_revenue(start_date=year_start)
    total_revenue = get_revenue()
    
    # Appointments by Day of Week
    # PostgreSQL / SQLite extract dow / isodow or just group by
    # For SQLite, it's safer to pull the last year's appointments and count in python to avoid dialect issues
    
    query_appts = db.query(Appointment.appointment_date)
    if current_user.role == "doctor":
        query_appts = query_appts.filter(Appointment.doctor_id == current_user.id)
        
    all_dates = [a[0] for a in query_appts.all()]
    
    days_of_week = [0] * 7 # Mon-Sun
    hours_of_day = [0] * 24 # 0-23
    
    for dt in all_dates:
        if dt:
            days_of_week[dt.weekday()] += 1
            hours_of_day[dt.hour] += 1
            
    # Format for charts
    day_labels = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
    appointments_by_day = [{"day": day_labels[i], "count": days_of_week[i]} for i in range(7)]
    appointments_by_time = [{"hour": f"{i:02d}:00", "count": hours_of_day[i]} for i in range(24) if hours_of_day[i] > 0 or (8 <= i <= 18)]

    return {
        "revenue_today": float(revenue_today),
        "revenue_month": float(revenue_month),
        "revenue_year": float(revenue_year),
        "total_revenue": float(total_revenue),
        "appointments_by_day_of_week": appointments_by_day,
        "appointments_by_time_of_day": appointments_by_time
    }