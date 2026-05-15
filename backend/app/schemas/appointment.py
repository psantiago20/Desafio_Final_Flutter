from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class PatientInfo(BaseModel):
    id: int
    name: str
    date_of_birth: Optional[datetime] = None

    class Config:
        from_attributes = True


class AppointmentBase(BaseModel):
    patient_id: int
    doctor_id: int
    medico_id: Optional[int] = None
    appointment_date: datetime
    duration_minutes: int = 30
    type: str = "consultation"
    reason: Optional[str] = None
    notes: Optional[str] = None
    price: float = 0.0


class AppointmentCreate(AppointmentBase):
    pass


class AppointmentUpdate(BaseModel):
    appointment_date: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    type: Optional[str] = None
    status: Optional[str] = None
    reason: Optional[str] = None
    notes: Optional[str] = None
    symptoms: Optional[str] = None
    diagnosis: Optional[str] = None
    prescription: Optional[str] = None
    prescription_html: Optional[str] = None
    weight: Optional[str] = None
    height: Optional[str] = None
    heart_rate: Optional[str] = None
    blood_pressure: Optional[str] = None
    glucose: Optional[str] = None
    temperature: Optional[str] = None
    price: Optional[float] = None
    paid: Optional[bool] = None
    payment_method: Optional[str] = None


class AppointmentResponse(AppointmentBase):
    id: int
    status: str
    patient: Optional[PatientInfo] = None
    doctor_name: Optional[str] = None
    medico_name: Optional[str] = None
    symptoms: Optional[str] = None
    diagnosis: Optional[str] = None
    prescription: Optional[str] = None
    prescription_html: Optional[str] = None
    weight: Optional[str] = None
    height: Optional[str] = None
    heart_rate: Optional[str] = None
    blood_pressure: Optional[str] = None
    glucose: Optional[str] = None
    temperature: Optional[str] = None
    exam_url: Optional[str] = None
    exam_summary: Optional[str] = None
    paid: bool
    payment_method: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class AppointmentStatusUpdate(BaseModel):
    status: str


class AppointmentListResponse(BaseModel):
    total: int
    appointments: list[AppointmentResponse]