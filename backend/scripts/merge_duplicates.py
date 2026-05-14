from app.db.database import SessionLocal
from app.models.patient import Patient
from app.models.message import Message
from app.models.appointment import Appointment
import sys

def merge_patients():
    db = SessionLocal()
    try:
        # Procurar pacientes com o mesmo telefone/whatsapp
        # Neste caso específico sabemos que é o 5515981829743
        phone = "5515981829743"
        patients = db.query(Patient).filter((Patient.phone == phone) | (Patient.whatsapp == phone)).all()
        
        if len(patients) <= 1:
            print(f"No duplicates found for {phone}")
            return

        # Identificar o real (tem user_id) e os fantasmas
        p_real = next((p for p in patients if p.user_id is not None), None)
        
        if not p_real:
            # Se nenhum tem user_id, pega o mais antigo
            patients.sort(key=lambda x: x.created_at)
            p_real = patients[0]
            p_ghosts = patients[1:]
        else:
            p_ghosts = [p for p in patients if p.id != p_real.id]

        print(f"Merging into Patient ID {p_real.id} ({p_real.name})")
        
        for p_ghost in p_ghosts:
            print(f" - Merging ghost Patient ID {p_ghost.id} ({p_ghost.name})...")
            
            # Mover mensagens
            msg_count = db.query(Message).filter(Message.patient_id == p_ghost.id).update({Message.patient_id: p_real.id})
            print(f"   * Moved {msg_count} messages")
            
            # Mover agendamentos
            app_count = db.query(Appointment).filter(Appointment.patient_id == p_ghost.id).update({Appointment.patient_id: p_real.id})
            print(f"   * Moved {app_count} appointments")
            
            # Deletar fantasma
            db.delete(p_ghost)
        
        db.commit()
        print("Done!")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == '__main__':
    merge_patients()
