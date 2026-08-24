from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional

from app.db.database import get_db
from app.models.medico import Medico
from app.schemas.medico import MedicoResponse # Vou precisar criar este schema
from app.api.endpoints.auth import get_current_user
from app.models.user import User

router = APIRouter()

@router.get("", response_model=List[MedicoResponse])
def list_medicos(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    medicos = db.query(Medico).filter(Medico.ativo == True).all()
    return medicos

@router.get("/{medico_id}", response_model=MedicoResponse)
def get_medico(
    medico_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    medico = db.query(Medico).filter(Medico.id == medico_id).first()
    if not medico:
        raise HTTPException(status_code=404, detail="Medico not found")
    return medico
