from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.db.database import Base


class Gender(str, enum.Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class Patient(Base):
    __tablename__ = "patients"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(200), nullable=False)
    email = Column(String(255), index=True)
    phone = Column(String(20), nullable=False)
    whatsapp = Column(String(20))
    date_of_birth = Column(DateTime)
    gender = Column(String(20))
    address = Column(String(300))
    city = Column(String(100))
    state = Column(String(50))
    cpf = Column(String(14))
    rg = Column(String(20))
    
    insurance = Column(String(100))
    insurance_number = Column(String(50))
    
    cep = Column(String(10))                                          # CEP do paciente
    preferencia_notificacao = Column(String(50), default="whatsapp")  # whatsapp, sms, email
    
    notes = Column(Text)
    tags = Column(Text)
    
    # Signos Vitais (Recentes)
    heart_rate = Column(String(10))
    blood_pressure = Column(String(20))
    glucose = Column(String(10))
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    appointments = relationship("Appointment", back_populates="patient")
    messages = relationship("Message", back_populates="patient")
    exams = relationship("Exam", back_populates="patient")
    user = relationship("User")