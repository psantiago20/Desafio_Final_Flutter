"""
doctor_mapper.py — Serviço de mapeamento WhatsApp Phone Number ID → Médico

Quando o webhook do WhatsApp recebe uma mensagem, o payload contém o
`phone_number_id` que identifica QUAL número WhatsApp recebeu a mensagem.
Este serviço consulta o DoctorProfile para descobrir a qual médico pertence
esse número, permitindo que o RAG busque a FAQ e dados corretos.
"""

import logging
from typing import Optional
from sqlalchemy.orm import Session

from app.models.doctor_profile import DoctorProfile

logger = logging.getLogger(__name__)


class DoctorMapper:
    """Mapeia phone_number_id do WhatsApp → DoctorProfile."""

    def get_doctor_by_phone_number_id(
        self, phone_number_id: str, db: Session
    ) -> Optional[DoctorProfile]:
        """
        Busca o perfil do médico pelo phone_number_id da Meta.
        
        Args:
            phone_number_id: ID do número WhatsApp (do payload da Meta)
            db: Sessão do banco de dados
            
        Returns:
            DoctorProfile ou None se não encontrado
        """
        if not phone_number_id:
            logger.warning("phone_number_id vazio recebido no DoctorMapper")
            return None

        doctor = db.query(DoctorProfile).filter(
            DoctorProfile.whatsapp_phone_number_id == phone_number_id,
            DoctorProfile.is_active == True
        ).first()

        if doctor:
            logger.info(f"Médico encontrado: user_id={doctor.user_id} para phone_number_id={phone_number_id}")
        else:
            logger.warning(f"Nenhum médico encontrado para phone_number_id={phone_number_id}")

        return doctor

    def get_doctor_by_user_id(
        self, user_id: int, db: Session
    ) -> Optional[DoctorProfile]:
        """Busca perfil do médico pelo user_id."""
        return db.query(DoctorProfile).filter(
            DoctorProfile.user_id == user_id,
            DoctorProfile.is_active == True
        ).first()

    def get_all_active_doctors(self, db: Session) -> list:
        """Retorna todos os médicos ativos com perfil WhatsApp configurado."""
        return db.query(DoctorProfile).filter(
            DoctorProfile.is_active == True
        ).all()


# Singleton
doctor_mapper = DoctorMapper()
