"""
simulator_admin.py — Endpoints de administração do simulador

Permite visualizar e manipular dados do banco (Médicos, Pacientes, Agendamentos)
e reiniciar a aplicação (quando rodando via uvicorn --reload).
"""

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import Dict, Any
import os
import time
import logging

from app.db.database import get_db
from app.models.medico import Medico
from app.models.patient import Patient
from app.models.appointment import Appointment

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/data")
def get_all_data(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Retorna todos os médicos, pacientes e agendamentos."""
    try:
        medicos = db.query(Medico).all()
        pacientes = db.query(Patient).all()
        agendamentos = db.query(Appointment).all()

        return {
            "status": "success",
            "data": {
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
    try:
        if table == "medicos":
            item = db.query(Medico).filter(Medico.id == item_id).first()
        elif table == "pacientes":
            item = db.query(Patient).filter(Patient.id == item_id).first()
        elif table == "agendamentos":
            item = db.query(Appointment).filter(Appointment.id == item_id).first()
        else:
            raise HTTPException(status_code=400, detail="Tabela inválida")

        if not item:
            raise HTTPException(status_code=404, detail="Registro não encontrado")

        db.delete(item)
        db.commit()
        return {"status": "success", "message": f"Registro {item_id} da tabela {table} deletado"}
    except Exception as e:
        logger.error(f"Erro ao deletar registro no simulador: {e}")
        raise HTTPException(status_code=500, detail=str(e))


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
    background_tasks.add_task(_touch_main_file)
    return {"status": "success", "message": "Reiniciando servidor em 1 segundo..."}
