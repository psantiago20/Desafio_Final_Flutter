"""
simulator_admin.py — Endpoints de administração do simulador

Permite visualizar e manipular dados do banco (Médicos, Pacientes, Agendamentos)
e reiniciar a aplicação (quando rodando via uvicorn --reload).
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Dict, Any
from pydantic import BaseModel
import os
import time
import logging

from app.db.database import get_db
from app.models.user import User
from app.models.medico import Medico
from app.models.patient import Patient
from app.models.appointment import Appointment
from app.core.config import settings
from fastapi import status

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/data")
def get_all_data(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Retorna todos os médicos, pacientes, agendamentos e usuários."""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    try:
        medicos = db.query(Medico).all()
        pacientes = db.query(Patient).all()
        agendamentos = db.query(Appointment).all()
        usuarios = db.query(User).all()

        return {
            "status": "success",
            "data": {
                "usuarios": [
                    {
                        "id": u.id,
                        "username": u.username,
                        "email": u.email,
                        "role": u.role,
                        "is_active": u.is_active
                    } for u in usuarios
                ],
                "medicos": [
                    {
                        "id": m.id,
                        "nome": m.nome_completo,
                        "crm": f"{m.crm}/{m.crm_estado}",
                        "especialidade": m.especialidade,
                        "cidade": getattr(m, 'cidade', 'N/A'),
                        "telefone": m.telefone
                    } for m in medicos
                ],
                "pacientes": [
                    {
                        "id": p.id,
                        "nome": p.name,
                        "cpf": p.cpf,
                        "whatsapp": p.whatsapp,
                        "cidade": p.city
                    } for p in pacientes
                ],
                "agendamentos": [
                    {
                        "id": a.id,
                        "paciente": a.patient.name if a.patient else f"ID {a.patient_id}",
                        "medico": a.medico.nome_completo if getattr(a, 'medico', None) else f"ID {a.medico_id}",
                        "data": a.appointment_date.strftime("%d/%m/%Y %H:%M") if a.appointment_date else "N/A",
                        "status": a.status,
                        "tipo": a.type
                    } for a in agendamentos
                ]
            }
        }
    except Exception as e:
        logger.error(f"Erro ao buscar dados do simulador: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/delete/{table}/{item_id}")
def delete_record(table: str, item_id: int, db: Session = Depends(get_db)):
    """Deleta um registro de uma tabela específica."""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    try:
        if table == "medicos":
            item = db.query(Medico).filter(Medico.id == item_id).first()
        elif table == "pacientes":
            item = db.query(Patient).filter(Patient.id == item_id).first()
        elif table == "agendamentos":
            item = db.query(Appointment).filter(Appointment.id == item_id).first()
        elif table == "usuarios":
            item = db.query(User).filter(User.id == item_id).first()
            if item:
                # Deletar perfis relacionados para evitar FK errors ou dados órfãos
                db.query(Patient).filter(Patient.user_id == item.id).delete()
                db.query(Medico).filter(Medico.user_id == item.id).delete()
        else:
            raise HTTPException(status_code=400, detail="Tabela inválida")

        if not item:
            raise HTTPException(status_code=404, detail="Registro não encontrado")

        db.delete(item)
        db.commit()
        return {"status": "success", "message": f"Registro {item_id} da tabela {table} deletado (e dados vinculados se houver)"}
    except Exception as e:
        logger.error(f"Erro ao deletar registro no simulador: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class EditPayload(BaseModel):
    data: Dict[str, Any]

@router.put("/edit/{table}/{item_id}")
def edit_record(table: str, item_id: int, payload: EditPayload, db: Session = Depends(get_db)):
    """Edita um registro de uma tabela específica."""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    try:
        if table == "usuarios":
            item = db.query(User).filter(User.id == item_id).first()
            if not item: raise HTTPException(status_code=404, detail="Usuário não encontrado")
            if "full_name" in payload.data: item.full_name = payload.data["full_name"]
            if "email" in payload.data: item.email = payload.data["email"]
            if "role" in payload.data: item.role = payload.data["role"]
            if "is_active" in payload.data: item.is_active = payload.data["is_active"]
        elif table == "medicos":
            item = db.query(Medico).filter(Medico.id == item_id).first()
            if not item: raise HTTPException(status_code=404, detail="Médico não encontrado")
            if "nome" in payload.data: item.nome_completo = payload.data["nome"]
            if "crm" in payload.data: 
                parts = payload.data["crm"].split('/')
                item.crm = parts[0]
                if len(parts) > 1: item.crm_estado = parts[1]
            if "especialidade" in payload.data: item.especialidade = payload.data["especialidade"]
            if "telefone" in payload.data: item.telefone = payload.data["telefone"]
            if "cidade" in payload.data: item.cidade = payload.data["cidade"]
        elif table == "pacientes":
            item = db.query(Patient).filter(Patient.id == item_id).first()
            if not item: raise HTTPException(status_code=404, detail="Paciente não encontrado")
            if "nome" in payload.data: item.name = payload.data["nome"]
            if "cpf" in payload.data: item.cpf = payload.data["cpf"]
            if "whatsapp" in payload.data: item.whatsapp = payload.data["whatsapp"]
            if "cidade" in payload.data: item.city = payload.data["cidade"]
        else:
            raise HTTPException(status_code=400, detail="Tabela inválida")

        db.commit()
        return {"status": "success", "message": f"Registro {item_id} da tabela {table} atualizado com sucesso"}
    except Exception as e:
        logger.error(f"Erro ao editar registro no simulador: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/debug")
def debug_db(db: Session = Depends(get_db)):
    """Retorna um resumo detalhado do banco de dados para depuração."""
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    try:
        users = db.query(User).all()
        medicos = db.query(Medico).all()
        pacientes = db.query(Patient).all()
        appointments = db.query(Appointment).all()
        
        return {
            "users_count": len(users),
            "users": [{"id": u.id, "username": u.username, "email": u.email, "role": u.role} for u in users],
            "medicos_count": len(medicos),
            "medicos": [{"id": m.id, "nome": m.nome_completo, "user_id": m.user_id} for m in medicos],
            "pacientes_count": len(pacientes),
            "pacientes": [{"id": p.id, "nome": p.name, "email": p.email, "user_id": p.user_id} for p in pacientes],
            "appointments_count": len(appointments),
            "appointments": [{"id": a.id, "patient_id": a.patient_id, "doctor_id": a.doctor_id, "status": a.status, "date": a.appointment_date.isoformat()} for a in appointments]
        }
    except Exception as e:
        return {"error": str(e)}

def _touch_main_file():
    """Toca o arquivo main.py para forçar o uvicorn a recarregar."""
    time.sleep(1)  # Dá tempo da resposta HTTP ser enviada
    main_file = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "main.py")
    if os.path.exists(main_file):
        os.utime(main_file, None)
        logger.info("🔁 Aplicação reiniciada via simulador (touch main.py)")


@router.post("/restart")
def restart_server(background_tasks: BackgroundTasks):
    """
    Aciona o reinício do servidor (funciona apenas se rodando com --reload).
    Usa BackgroundTasks para retornar o status 200 antes de reiniciar.
    """
    if not settings.DEBUG:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Disabled in production")
    background_tasks.add_task(_touch_main_file)
    return {"status": "success", "message": "Reiniciando servidor em 1 segundo..."}
