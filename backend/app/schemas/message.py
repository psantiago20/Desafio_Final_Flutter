from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class PatientInfo(BaseModel):
    id: int
    name: str
    phone: str
    whatsapp: Optional[str] = None

    class Config:
        from_attributes = True


class MessageBase(BaseModel):
    patient_id: int
    content: str
    message_type: str = "text"
    source: str = "app"


class MessageCreate(MessageBase):
    sender_id: Optional[int] = None
    receiver_id: Optional[int] = None


class MessageUpdate(BaseModel):
    is_read: Optional[bool] = None
    is_delivered: Optional[bool] = None
    content: Optional[str] = None


class MessageResponse(MessageBase):
    id: int
    sender_id: Optional[int] = None
    receiver_id: Optional[int] = None
    wa_message_id: Optional[str] = None
    wa_from: Optional[str] = None
    is_read: bool
    is_delivered: bool
    meta: Optional[str] = None
    created_at: datetime
    patient: PatientInfo

    class Config:
        from_attributes = True


class MessageListResponse(BaseModel):
    total: int
    messages: list[MessageResponse]
