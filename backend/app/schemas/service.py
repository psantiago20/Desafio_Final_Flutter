from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class ServiceBase(BaseModel):
    patient_id: Optional[int] = None
    appointment_id: Optional[int] = None
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    priority: str = "normal"
    price: float = 0.0
    cost: float = 0.0


class ServiceCreate(ServiceBase):
    pass


class ServiceUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    status: Optional[str] = None
    priority: Optional[str] = None
    price: Optional[float] = None
    cost: Optional[float] = None
    ai_suggestion: Optional[str] = None
    ai_classification: Optional[str] = None
    documents: Optional[str] = None


class ServiceResponse(ServiceBase):
    id: int
    status: str
    ai_suggestion: Optional[str] = None
    ai_classification: Optional[str] = None
    documents: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ServiceListResponse(BaseModel):
    total: int
    services: list[ServiceResponse]