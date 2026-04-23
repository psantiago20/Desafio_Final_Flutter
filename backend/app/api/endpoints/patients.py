from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.db.database import get_db
from app.models.patient import Patient
from app.schemas.patient import PatientCreate, PatientUpdate, PatientResponse, PatientListResponse
from app.api.endpoints.auth import get_current_user
from app.models.user import User

router = APIRouter()


@router.get("", response_model=PatientListResponse)
def list_patients(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Patient).filter(Patient.is_active == True)
    
    if search:
        query = query.filter(
            (Patient.name.ilike(f"%{search}%")) |
            (Patient.phone.ilike(f"%{search}%")) |
            (Patient.email.ilike(f"%{search}%"))
        )
    
    total = query.count()
    patients = query.offset(skip).limit(limit).all()
    
    return {"total": total, "patients": patients}


@router.get("/{patient_id}", response_model=PatientResponse)
def get_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@router.post("", response_model=PatientResponse, status_code=status.HTTP_201_CREATED)
def create_patient(
    patient: PatientCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_patient = Patient(**patient.model_dump())
    db.add(db_patient)
    db.commit()
    db.refresh(db_patient)
    return db_patient


@router.put("/{patient_id}", response_model=PatientResponse)
def update_patient(
    patient_id: int,
    patient: PatientUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    update_data = patient.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_patient, key, value)
    
    db.commit()
    db.refresh(db_patient)
    return db_patient


@router.delete("/{patient_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    db_patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not db_patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    db_patient.is_active = False
    db.commit()
    return None