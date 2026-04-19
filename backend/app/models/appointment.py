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
    
    appointment_date = Column(DateTime, nullable=False)
    duration_minutes = Column(Integer, default=30)
    type = Column(String(50), default=AppointmentType.CONSULTATION.value)
    status = Column(String(50), default=AppointmentStatus.PENDING.value)
    
    reason = Column(Text)
    notes = Column(Text)
    symptoms = Column(Text)
    diagnosis = Column(Text)
    prescription = Column(Text)
    
    price = Column(Float, default=0.0)
    paid = Column(Boolean, default=False)
    payment_method = Column(String(50))
    
    is_recurring = Column(Boolean, default=False)
    recurring_id = Column(Integer)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    patient = relationship("Patient", back_populates="appointments")
    doctor = relationship("User", back_populates="appointments")