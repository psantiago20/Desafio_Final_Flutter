from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from datetime import datetime
import enum
from app.db.database import Base


class MessageType(str, enum.Enum):
    TEXT = "text"
    IMAGE = "image"
    AUDIO = "audio"
    VIDEO = "video"
    DOCUMENT = "document"
    SYSTEM = "system"


class MessageSource(str, enum.Enum):
    WHATSAPP = "whatsapp"
    APP = "app"
    SYSTEM = "system"


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    
    patient_id = Column(Integer, ForeignKey("patients.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"))
    receiver_id = Column(Integer, ForeignKey("users.id"))
    
    content = Column(Text, nullable=False)
    message_type = Column(String(20), default=MessageType.TEXT.value)
    source = Column(String(20), default=MessageSource.APP.value)
    
    wa_message_id = Column(String(100))
    wa_from = Column(String(20))
    
    is_read = Column(Boolean, default=False)
    is_delivered = Column(Boolean, default=False)
    
    meta = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)

    patient = relationship("Patient", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id], back_populates="messages_sent")
    receiver = relationship("User", foreign_keys=[receiver_id], back_populates="messages_received")