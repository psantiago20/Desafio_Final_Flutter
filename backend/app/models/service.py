from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float, Enum
from datetime import datetime
import enum
from app.db.database import Base


class ServiceStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    WAITING_PAYMENT = "waiting_payment"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    
    patient_id = Column(Integer, ForeignKey("patients.id"))
    appointment_id = Column(Integer, ForeignKey("appointments.id"))
    
    name = Column(String(200), nullable=False)
    description = Column(Text)
    category = Column(String(50))
    
    status = Column(String(50), default=ServiceStatus.PENDING.value)
    priority = Column(String(20), default="normal")
    
    price = Column(Float, default=0.0)
    cost = Column(Float, default=0.0)
    
    ai_suggestion = Column(Text)
    ai_classification = Column(String(100))
    
    documents = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    completed_at = Column(DateTime)