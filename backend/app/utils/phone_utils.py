import re
from typing import Optional

from sqlalchemy.orm import Session, joinedload

from app.models.patient import Patient
from app.models.user import User


def digits_only(value: Optional[str]) -> str:
    if not value:
        return ""
    return re.sub(r"\D", "", value)


def br_mobile_key(digits: str) -> str:
    """
    Normaliza para comparar linhas móveis BR com o que a Meta envia (ex.: 5511...).
    Remove prefixo 55 e usa até os últimos 11 dígitos (DDD + número).
    """
    d = digits_only(digits)
    if not d:
        return ""
    if d.startswith("55") and len(d) >= 12:
        d = d[2:]
    if len(d) >= 11:
        return d[-11:]
    if len(d) >= 10:
        return d[-10:]
    return d


def same_messaging_line(a: Optional[str], b: Optional[str]) -> bool:
    if not a or not b:
        return False
    ka, kb = br_mobile_key(a), br_mobile_key(b)
    if not ka or not kb:
        return False
    return ka == kb


def find_patient_by_messaging_phone(db: Session, wa_from: Optional[str]) -> Optional[Patient]:
    """
    Localiza paciente pelo número usado no WhatsApp / cadastro.
    Prioriza pacientes que possuem conta vinculada (user_id is not null).
    """
    if not wa_from:
        return None

    # Normalizar para busca
    target = digits_only(wa_from)
    
    # Busca direta por whatsapp ou phone, ordenando para pegar quem tem user_id primeiro
    patient = (
        db.query(Patient)
        .filter((Patient.whatsapp == wa_from) | (Patient.phone == wa_from) | (Patient.whatsapp == target) | (Patient.phone == target))
        .order_by(Patient.user_id.desc().nulls_last())
        .first()
    )
    if patient:
        return patient

    # Busca avançada por similaridade (key de 11 dígitos)
    q = (
        db.query(Patient)
        .options(joinedload(Patient.user))
        .filter(Patient.is_active.is_(True))
        .order_by(Patient.user_id.desc().nulls_last())
    )
    
    for p in q.all():
        if same_messaging_line(wa_from, p.whatsapp) or same_messaging_line(wa_from, p.phone):
            return p
        if p.user and p.user.phone and same_messaging_line(wa_from, p.user.phone):
            return p
            
    return None


def find_patient_for_contact(db: Session, raw: Optional[str]) -> Optional[Patient]:
    """Telefone/WhatsApp ou e-mail (upload de exame aceita email como identificador)."""
    if not raw:
        return None
    if "@" in raw:
        return db.query(Patient).filter(Patient.email == raw).first()
    return find_patient_by_messaging_phone(db, raw)


def ensure_canonical_whatsapp(db: Session, patient: Patient, wa_from: str) -> None:
    """Grava o wa_from da Meta no paciente para próximas buscas serem exatas."""
    if not patient or not wa_from:
        return
    if patient.whatsapp == wa_from:
        return
    patient.whatsapp = wa_from
    db.add(patient)
    db.commit()
