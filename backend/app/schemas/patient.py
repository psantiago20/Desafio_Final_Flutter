from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class PatientBase(BaseModel):
    name: str
    email: Optional[str] = None
    phone: str
    whatsapp: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    cpf: Optional[str] = None
    rg: Optional[str] = None
    insurance: Optional[str] = None
    insurance_number: Optional[str] = None
    notes: Optional[str] = None
    tags: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    medications: Optional[str] = None


class PatientCreate(PatientBase):
    pass


class PatientUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    whatsapp: Optional[str] = None
    date_of_birth: Optional[datetime] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    cpf: Optional[str] = None
    rg: Optional[str] = None
    insurance: Optional[str] = None
    insurance_number: Optional[str] = None
    notes: Optional[str] = None
    tags: Optional[str] = None
    blood_type: Optional[str] = None
    allergies: Optional[str] = None
    chronic_conditions: Optional[str] = None
    medications: Optional[str] = None
    is_active: Optional[bool] = None


class PatientResponse(PatientBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PatientListResponse(BaseModel):
    total: int
    patients: list[PatientResponse]