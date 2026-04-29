"""
doctor_mapper.py — Serviço de mapeamento WhatsApp Phone Number ID → Médico

Quando o webhook do WhatsApp recebe uma mensagem, o payload contém o
`phone_number_id` que identifica QUAL número WhatsApp recebeu a mensagem.
Este serviço consulta a tabela `medicos` para descobrir a qual médico pertence
esse número, permitindo que o agente busque a FAQ e dados corretos.
"""

import logging
from typing import Optional
from sqlalchemy.orm import Session

from app.models.medico import Medico

logger = logging.getLogger(__name__)


class DoctorMapper:
    """Mapeia phone_number_id do WhatsApp → Medico."""

    def get_doctor_by_phone_number_id(
        self, phone_number_id: str, db: Session
    ) -> Optional[Medico]:
        """
        Busca o médico pelo phone_number_id da Meta.
        
        Args:
            phone_number_id: ID do número WhatsApp (do payload da Meta)
            db: Sessão do banco de dados
            
        Returns:
            Medico ou None se não encontrado
        """
        if not phone_number_id:
            logger.warning("phone_number_id vazio recebido no DoctorMapper")
            return None

        medico = db.query(Medico).filter(
            Medico.whatsapp_phone_number_id == phone_number_id,
            Medico.ativo == True
        ).first()

        if medico:
            logger.info(f"Médico encontrado: id={medico.id}, nome={medico.nome_completo} para phone_number_id={phone_number_id}")
        else:
            logger.warning(f"Nenhum médico encontrado para phone_number_id={phone_number_id}")

        return medico

    def get_doctor_by_id(
        self, medico_id: int, db: Session
    ) -> Optional[Medico]:
        """Busca médico pelo ID."""
        return db.query(Medico).filter(
            Medico.id == medico_id,
            Medico.ativo == True
        ).first()

    def get_all_active_doctors(self, db: Session) -> list:
        """Retorna todos os médicos ativos com WhatsApp configurado."""
        return db.query(Medico).filter(
            Medico.ativo == True
        ).all()


# Singleton
doctor_mapper = DoctorMapper()
