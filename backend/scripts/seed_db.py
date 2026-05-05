
import sys
import os
from sqlalchemy.orm import Session
from datetime import datetime

# Adicionar o path do backend para importar os modelos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal, engine, Base
from app.models.medico import Medico
from app.models.patient import Patient
from app.models.appointment import Appointment

def seed():
    db = SessionLocal()
    try:
        # 1. Limpar dados existentes (opcional para evitar duplicatas em testes)
        # db.query(Appointment).delete()
        # db.query(Patient).delete()
        # db.query(Medico).delete()
        # db.commit()

        print("Iniciando seed de dados...")

        # 2. Criar Médicos
        doctors_data = [
            {
                "nome_completo": "Dra. Marina Costa",
                "crm": "123456",
                "crm_estado": "SP",
                "especialidade": "Clínica Geral",
                "email": "marina.costa@suaconsulta.com",
                "telefone": "(11) 99999-0001",
                "cidade": "São Paulo",
                "endereco": "Av. Paulista, 1000 - Bela Vista",
                "valor_consulta": 250.00,
                "aceita_convenio": True,
                "convenios": '["Unimed", "Bradesco", "SulAmérica"]',
                "bio_resumida": "Médica dedicada com foco em atendimento humanizado e prevenção."
            },
            {
                "nome_completo": "Dr. Thorne Blackwood",
                "crm": "654321",
                "crm_estado": "RJ",
                "especialidade": "Cardiologia",
                "email": "thorne.blackwood@suaconsulta.com",
                "telefone": "(21) 98888-0002",
                "cidade": "Rio de Janeiro",
                "endereco": "Rua Visconde de Pirajá, 500 - Ipanema",
                "valor_consulta": 400.00,
                "aceita_convenio": False,
                "bio_resumida": "Especialista em arritmias e saúde do coração."
            }
        ]

        doctors = []
        for d in doctors_data:
            existing = db.query(Medico).filter(Medico.crm == d["crm"]).first()
            if not existing:
                doc = Medico(**d)
                db.add(doc)
                doctors.append(doc)
                print(f"Médico criado: {d['nome_completo']}")
            else:
                doctors.append(existing)

        db.commit()

        # 3. Criar Pacientes
        patients_data = [
            {
                "name": "Pedro Santiago",
                "cpf": "123.456.789-00",
                "phone": "5511988888888",
                "whatsapp": "5511988888888",
                "city": "São Paulo",
                "state": "SP",
                "insurance": "Unimed"
            },
            {
                "name": "Maria Oliveira",
                "cpf": "987.654.321-11",
                "phone": "5511977777777",
                "whatsapp": "5511977777777",
                "city": "São Paulo",
                "state": "SP"
            }
        ]

        patients = []
        for p in patients_data:
            existing = db.query(Patient).filter(Patient.cpf == p["cpf"]).first()
            if not existing:
                pat = Patient(**p)
                db.add(pat)
                patients.append(pat)
                print(f"Paciente criado: {p['name']}")
            else:
                patients.append(existing)
        
        db.commit()

        # 4. Criar alguns agendamentos
        if doctors and patients:
            # Agendamento para hoje
            existing_app = db.query(Appointment).filter(Appointment.patient_id == patients[0].id).first()
            if not existing_app:
                app1 = Appointment(
                    patient_id=patients[0].id,
                    medico_id=doctors[0].id,
                    appointment_date=datetime.utcnow(),
                    status="confirmed",
                    type="consulta",
                    reason="Check-up de rotina"
                )
                db.add(app1)
                print(f"Agendamento criado para {patients[0].name}")

        db.commit()
        print("Seed concluído com sucesso!")

    except Exception as e:
        print(f"Erro no seed: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
