from fastapi import APIRouter, Depends, Query
from sqlalchemy import func
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
from pydantic import BaseModel

from app.db.database import get_db
from app.models.appointment import Appointment
from app.models.service import Service
from app.api.endpoints.auth import get_current_user
from app.models.user import User

router = APIRouter()


class FinanceReport(BaseModel):
    total_revenue: float
    total_paid: float
    total_pending: float
    total_cancelled: float
    by_payment_method: dict
    by_type: dict
    by_day: list


@router.get("/reports", response_model=FinanceReport)
def get_finance_reports(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not start_date:
        start_date = datetime.utcnow() - timedelta(days=30)
    if not end_date:
        end_date = datetime.utcnow()
    
    appointments = db.query(Appointment).filter(
        Appointment.appointment_date >= start_date,
        Appointment.appointment_date <= end_date
    ).all()
    
    total_revenue = sum(a.price for a in appointments)
    total_paid = sum(a.price for a in appointments if a.paid)
    total_pending = sum(a.price for a in appointments if not a.paid and a.status != "cancelled")
    total_cancelled = sum(a.price for a in appointments if a.status == "cancelled")
    
    by_method = {}
    for apt in appointments:
        method = apt.payment_method or "not_specified"
        by_method[method] = by_method.get(method, 0) + apt.price
    
    by_type = {}
    for apt in appointments:
        by_type[apt.type] = by_type.get(apt.type, 0) + apt.price
    
    by_day_data = {}
    for apt in appointments:
        day = apt.appointment_date.date().isoformat()
        by_day_data[day] = by_day_data.get(day, 0) + apt.price
    
    by_day = [{"date": k, "revenue": v} for k, v in sorted(by_day_data.items())]
    
    return {
        "total_revenue": total_revenue,
        "total_paid": total_paid,
        "total_pending": total_pending,
        "total_cancelled": total_cancelled,
        "by_payment_method": by_method,
        "by_type": by_type,
        "by_day": by_day
    }


@router.get("/kpis")
def get_finance_kpis(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today = datetime.utcnow().date()
    month_start = today.replace(day=1)
    
    this_month = db.query(Appointment).filter(
        func.date(Appointment.appointment_date) >= month_start,
        Appointment.paid == True
    ).all()
    
    last_month_start = (month_start - timedelta(days=1)).replace(day=1)
    last_month = db.query(Appointment).filter(
        func.date(Appointment.appointment_date) >= last_month_start,
        func.date(Appointment.appointment_date) < month_start,
        Appointment.paid == True
    ).all()
    
    this_month_revenue = sum(a.price for a in this_month)
    last_month_revenue = sum(a.price for a in last_month)
    
    growth = ((this_month_revenue - last_month_revenue) / last_month_revenue * 100) if last_month_revenue > 0 else 0
    
    return {
        "this_month_revenue": this_month_revenue,
        "last_month_revenue": last_month_revenue,
        "growth_percentage": round(growth, 2),
        "total_appointments_this_month": len(this_month),
        "average_ticket": this_month_revenue / len(this_month) if this_month else 0
    }