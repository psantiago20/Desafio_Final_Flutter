from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class DoctorProfile(Base):
    """
    Perfil do médico com mapeamento para o WhatsApp Business.
    Cada médico contratante recebe um número WhatsApp próprio (phone_number_id da Meta).
    O RAG usa este mapeamento para identificar de qual médico é a FAQ/dados quando
    uma mensagem chega pelo webhook.
    """
    __tablename__ = "doctor_profiles"

    id = Column(Integer, primary_key=True, index=True)

    # FK para o User com role "doctor"
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)

    # Identificação WhatsApp Business
    whatsapp_phone_number_id = Column(String(50), unique=True, nullable=False, index=True)
    whatsapp_access_token = Column(String(500), nullable=True)

    # Dados da clínica / consultório
    clinic_name = Column(String(200))
    clinic_address = Column(String(500))
    clinic_phone = Column(String(20))
    clinic_email = Column(String(255))

    # Dados profissionais (usados como contexto no RAG)
    specialties = Column(Text)            # JSON array: ["Clínica Geral", "Cardiologia"]
    working_hours = Column(Text)          # JSON: {"seg": "08:00-18:00", ...}
    accepted_insurances = Column(Text)    # JSON array: ["Unimed", "Bradesco", ...]
    consultation_duration = Column(Integer, default=30)  # minutos
    consultation_price = Column(String(50))               # "R$ 250,00"

    # Controle
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", backref="doctor_profile")
