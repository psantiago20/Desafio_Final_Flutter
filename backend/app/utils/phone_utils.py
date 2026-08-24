import re
from typing import Optional, Set

from sqlalchemy.orm import Session, joinedload

from app.models.patient import Patient
from app.models.user import User


def digits_only(value: Optional[str]) -> str:
    if not value:
        return ""
    return re.sub(r"\D", "", value)


def canonical_phone_candidates(value: Optional[str]) -> Set[str]:
    """
    Retorna apenas formas deterministicas do mesmo numero.
    Nao tenta inferir linhas parecidas; isso evita vincular conversas de pessoas diferentes.
    """
    d = digits_only(value)
    if not d:
        return set()

    candidates = {d}
    if d.startswith("55") and len(d) >= 12:
        candidates.add(d[2:])
    elif len(d) in (10, 11):
        candidates.add(f"55{d}")
    return candidates


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


def find_patient_by_exact_messaging_phone(db: Session, phone: Optional[str]) -> Optional[Patient]:
    """
    Busca estrita para vincular cadastro/perfil a conversas pre-existentes.
    Se houver mais de um paciente possivel para o mesmo numero canonico, nao vincula.
    """
    candidates = canonical_phone_candidates(phone)
    if not candidates:
        return None

    matches = (
        db.query(Patient)
        .filter(
            (Patient.whatsapp.in_(candidates)) |
            (Patient.phone.in_(candidates))
        )
        .all()
    )
    unique = {patient.id: patient for patient in matches}
    if len(unique) == 1:
        return next(iter(unique.values()))
    return None


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
    # Tenta também sem o DDI (55) se estiver presente
    target_no_ddi = target[2:] if target.startswith("55") and len(target) >= 12 else target
    
    # 1. Busca direta (mais rápida e exata)
    patient = (
        db.query(Patient)
        .filter(
            (Patient.whatsapp == wa_from) | 
            (Patient.phone == wa_from) | 
            (Patient.whatsapp == target) | 
            (Patient.phone == target) |
            (Patient.whatsapp == target_no_ddi) |
            (Patient.phone == target_no_ddi)
        )
        .order_by(Patient.user_id.desc().nulls_last())
        .first()
    )
    if patient:
        return patient

    # 2. Busca avançada por similaridade (key de 10-11 dígitos)
    key_wa = br_mobile_key(wa_from)
    q = (
        db.query(Patient)
        .options(joinedload(Patient.user))
        .filter(Patient.is_active.is_(True))
    )
    
    candidates = []
    for p in q.all():
        if same_messaging_line(wa_from, p.whatsapp) or same_messaging_line(wa_from, p.phone):
            candidates.append(p)
        elif p.user and p.user.phone and same_messaging_line(wa_from, p.user.phone):
            candidates.append(p)
            
    if candidates:
        # Ordena candidatos: 
        # 1. Quem tem user_id (conta vinculada)
        # 2. Quem tem o whatsapp mais similar (apenas dígitos)
        # 3. ID menor (criado antes)
        candidates.sort(key=lambda x: (
            x.user_id is not None,
            digits_only(x.whatsapp) == target,
            -x.id
        ), reverse=True)
        return candidates[0]
            
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
