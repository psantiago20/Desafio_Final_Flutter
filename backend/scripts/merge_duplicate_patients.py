import sys
import os
from sqlalchemy import text
from sqlalchemy.orm import Session

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.db.database import engine, SessionLocal
from app.models.patient import Patient
from app.models.message import Message
from app.models.appointment import Appointment
from app.models.exam import Exam
from app.utils.phone_utils import br_mobile_key, digits_only

def merge_patients():
    db = SessionLocal()
    print("Iniciando mesclagem de pacientes duplicados...")

    all_patients = db.query(Patient).all()
    
    # Agrupar por key de telefone (11 dígitos normalizados)
    grouped = {}
    for p in all_patients:
        # Se não tiver telefone nem whatsapp, ignora ou usa o ID
        key = br_mobile_key(p.whatsapp or p.phone)
        if not key:
            continue
            
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(p)

    for key, patients in grouped.items():
        if len(patients) <= 1:
            continue
            
        print(f"\nDetectados {len(patients)} registros para o número final {key}:")
        
        # Eleger o "Paciente Mestre"
        # Prioridade: 1. Tem user_id, 2. Nome não começa com "WhatsApp User", 3. ID menor
        patients.sort(key=lambda x: (
            x.user_id is not None,
            not x.name.startswith("WhatsApp User"),
            -x.id
        ), reverse=True)
        
        master = patients[0]
        duplicates = patients[1:]
        
        print(f"  MESTRE: ID {master.id} - {master.name} (User: {master.user_id})")
        
        for dup in duplicates:
            print(f"  DUPLICADO: ID {dup.id} - {dup.name} -> Mesclando...")
            
            # 1. Mover Mensagens
            msg_count = db.query(Message).filter(Message.patient_id == dup.id).update({"patient_id": master.id})
            
            # 2. Mover Agendamentos
            appt_count = db.query(Appointment).filter(Appointment.patient_id == dup.id).update({"patient_id": master.id})
            
            # 3. Mover Exames
            exam_count = db.query(Exam).filter(Exam.patient_id == dup.id).update({"patient_id": master.id})
            
            # 4. Se o duplicado tinha user_id e o mestre não (caso raro pela ordenação), transfere
            if dup.user_id and not master.user_id:
                master.user_id = dup.user_id
            
            # 5. Deletar o duplicado
            db.delete(dup)
            print(f"    OK: {msg_count} msgs, {appt_count} appts, {exam_count} exams movidos.")

    try:
        db.commit()
        print("\nSucesso! Todos os duplicados foram mesclados.")
    except Exception as e:
        db.rollback()
        print(f"\nERRO ao commitar mudanças: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    merge_patients()
