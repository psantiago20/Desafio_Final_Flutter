from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.db.database import Base


class AppointmentStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"


class AppointmentType(str, enum.Enum):
    CONSULTATION = "consultation"
    RETURN = "return"
    EXAM = "exam"
    PROCEDURE = "procedure"
    FOLLOW_UP = "follow_up"


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(Integer, primary_key=True, index=True)
    
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    medico_id = Column(Integer, ForeignKey("medicos.id"), nullable=True)  # FK para novo model Medico
    
    appointment_date = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, default=30)
    type = Column(String(50), default=AppointmentType.CONSULTATION.value)
    status = Column(String(50), default=AppointmentStatus.PENDING.value)
    
    reason = Column(Text)
    notes = Column(Text)
    symptoms = Column(Text)
    diagnosis = Column(Text)
    prescription = Column(Text)
    prescription_html = Column(Text)
    exam_url = Column(String(255), nullable=True)
    exam_summary = Column(Text, nullable=True)
    
    # Novos campos clínicos (Signos Vitais)
    weight = Column(String(20), nullable=True)
    height = Column(String(20), nullable=True)
    heart_rate = Column(String(20), nullable=True)
    blood_pressure = Column(String(20), nullable=True)
    glucose = Column(String(20), nullable=True)
    temperature = Column(String(20), nullable=True)
    
    price = Column(Float, default=0.0)
    paid = Column(Boolean, default=False)
    payment_method = Column(String(50))
    
    is_recurring = Column(Boolean, default=False)
    recurring_id = Column(Integer)
    
    # canal_notificacao = Column(String(50), default="whatsapp")  # whatsapp, sms, email
    # notificado_em = Column(DateTime, nullable=True)
    
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)

    patient = relationship("Patient", back_populates="appointments")
    doctor = relationship("User", back_populates="appointments")
    medico = relationship("Medico", back_populates="agendamentos", foreign_keys=[medico_id])