from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime

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
    

@router.get("/me", response_model=PatientResponse)
def get_my_patient_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "patient":
        raise HTTPException(status_code=403, detail="Only patients can access their own profile")
        
    print(f"[DEBUG] Fetching patient profile for user_id: {current_user.id}")
    patient = db.query(Patient).filter(Patient.user_id == current_user.id).first()
    
    if not patient:
        print(f"[DEBUG] Creating/Linking patient record for user {current_user.id}")
        from app.utils.phone_utils import find_patient_by_messaging_phone, digits_only
        
        try:
            # Tenta localizar paciente pré-existente pelo telefone do User
            phone_clean = digits_only(current_user.phone) if current_user.phone else None
            patient = find_patient_by_messaging_phone(db, phone_clean) if phone_clean else None
            
            if patient:
                # Vincula paciente órfão ao usuário logado
                patient.user_id = current_user.id
                if not patient.email:
                    patient.email = current_user.email
                db.add(patient)
            else:
                # Cria novo paciente se não existir nada
                patient = Patient(
                    user_id=current_user.id,
                    name=current_user.full_name or current_user.username or "Usuário",
                    email=current_user.email,
                    phone=current_user.phone or "00000000000",
                    whatsapp=current_user.phone or "00000000000",
                    is_active=True
                )
                db.add(patient)
            
            db.commit()
            db.refresh(patient)
        except Exception as e:
            db.rollback()
            print(f"[ERROR] Could not create or link patient record: {e}")
            # Fallback para perfil virtual se a criação no banco falhar
            return {
                "id": 0,
                "name": current_user.full_name or current_user.username or "Usuário",
                "email": current_user.email,
                "phone": current_user.phone or "00000000000",
                "whatsapp": current_user.phone or "00000000000",
                "date_of_birth": None,
                "gender": None,
                "address": None,
                "city": None,
                "state": None,
                "cpf": None,
                "rg": None,
                "insurance": None,
                "insurance_number": None,
                "notes": None,
                "tags": None,
                "blood_type": None,
                "allergies": None,
                "chronic_conditions": None,
                "medications": None,
                "is_active": True,
                "created_at": current_user.created_at,
                "updated_at": current_user.created_at,
            }
    
    print(f"[DEBUG] Patient found: {patient.id}")
    return {
        "id": patient.id,
        "name": patient.name,
        "email": patient.email,
        "phone": patient.phone,
        "whatsapp": patient.whatsapp,
        "date_of_birth": patient.date_of_birth,
        "gender": patient.gender,
        "address": patient.address,
        "city": patient.city,
        "state": patient.state,
        "cpf": patient.cpf,
        "rg": patient.rg,
        "insurance": patient.insurance,
        "insurance_number": patient.insurance_number,
        "notes": patient.notes,
        "tags": patient.tags,
        "blood_type": patient.blood_type,
        "allergies": patient.allergies,
        "chronic_conditions": patient.chronic_conditions,
        "medications": patient.medications,
        "is_active": patient.is_active,
        "created_at": patient.created_at,
        "updated_at": patient.updated_at,
    }


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
    from app.utils.phone_utils import find_patient_by_messaging_phone
    
    # Verificar se já existe um paciente com este telefone ou whatsapp
    existing = find_patient_by_messaging_phone(db, patient.phone)
    if not existing and patient.whatsapp:
        existing = find_patient_by_messaging_phone(db, patient.whatsapp)
        
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Já existe um paciente cadastrado com este número (ID: {existing.id})"
        )

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