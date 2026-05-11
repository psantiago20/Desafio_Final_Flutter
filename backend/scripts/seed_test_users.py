import sys
import os
from sqlalchemy.orm import Session

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.models.user import User, UserRole
from app.models.medico import Medico
from app.services.auth_service import get_password_hash

def seed_users():
    db = SessionLocal()
    try:
        print("Semeando usuários de teste...")

        # 1. Criar Paciente de Teste
        patient_email = "paciente@teste.com"
        db_patient = db.query(User).filter(User.email == patient_email).first()
        if not db_patient:
            db_patient = User(
                email=patient_email,
                username="paciente_teste",
                full_name="Paciente de Teste",
                role=UserRole.PATIENT.value,
                hashed_password=get_password_hash("senha123"),
                is_active=True
            )
            db.add(db_patient)
            print(f"Usuário {patient_email} criado.")
        else:
            print(f"Usuário {patient_email} já existe.")

        # 2. Criar Médico de Teste
        doctor_email = "medico@teste.com"
        doctor_crm = "CRM-TESTE-999"
        db_doctor = db.query(User).filter(User.email == doctor_email).first()
        
        if not db_doctor:
            db_doctor = User(
                email=doctor_email,
                username="medico_teste",
                full_name="Dr. Teste Silva",
                role=UserRole.DOCTOR.value,
                hashed_password=get_password_hash("senha123"),
                is_active=True
            )
            db.add(db_doctor)
            db.flush() # Para pegar o ID
            print(f"Usuário {doctor_email} preparado.")
        else:
            print(f"Usuário {doctor_email} já existe.")

        # Verificar perfil de médico
        medico_profile = db.query(Medico).filter(Medico.crm == doctor_crm).first()
        if not medico_profile:
            # Tentar achar pelo email também
            medico_profile = db.query(Medico).filter(Medico.email == doctor_email).first()
            
        if not medico_profile:
            medico_profile = Medico(
                nome_completo="Dr. Teste Silva",
                crm=doctor_crm,
                crm_estado="SP",
                especialidade="Clínico Geral",
                email=doctor_email,
                user_id=db_doctor.id if db_doctor else None
            )
            db.add(medico_profile)
            print(f"Perfil médico {doctor_crm} criado.")
        else:
            print(f"Perfil médico {doctor_crm} já existe.")

        db.commit()
        print("Semeação concluída com sucesso!")
        print("\nLogins de teste:")
        print(f"PACIENTE: {patient_email} / senha123")
        print(f"MÉDICO:   {doctor_email} / senha123 (CRM: {doctor_crm})")

    except Exception as e:
        print(f"Erro ao semear usuários: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_users()
