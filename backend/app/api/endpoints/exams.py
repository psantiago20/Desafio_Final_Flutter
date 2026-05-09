from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from app.db.database import get_db
from app.models.exam import Exam
from app.models.patient import Patient
from app.api.endpoints.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("")
def list_exams(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Exam).join(Patient)
    
    # Se for paciente, vê apenas os seus
    if current_user.role == "patient":
        query = query.filter(Patient.email == current_user.email)
    
    exams = query.order_by(Exam.created_at.desc()).all()
    return {"total": len(exams), "exams": exams}

@router.get("/{exam_id}")
def get_exam(
    exam_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
        
    # Verificação de permissão simples
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
        if not patient or exam.patient_id != patient.id:
            raise HTTPException(status_code=403, detail="Not authorized")
            
    return exam

@router.delete("/{exam_id}")
def delete_exam(
    exam_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    print(f"[DEBUG] Tentativa de deletar exame {exam_id} por usuário {current_user.email} (role: {current_user.role})")
    exam = db.query(Exam).filter(Exam.id == exam_id).first()
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
        
    # Verificação de permissão
    if current_user.role == "patient":
        patient = db.query(Patient).filter(Patient.email == current_user.email).first()
        if not patient or exam.patient_id != patient.id:
            raise HTTPException(status_code=403, detail="Not authorized")
    elif current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
            
    db.delete(exam)
    db.commit()
    print(f"[DEBUG] Exame {exam_id} deletado com sucesso")
    return {"message": "Exam deleted successfully"}

