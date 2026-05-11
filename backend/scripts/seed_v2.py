
import sys
import os
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

# Adicionar o path do backend para importar os modelos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal, engine, Base
from app.models.user import User, UserRole
from app.models.medico import Medico
from app.models.patient import Patient, Gender
from app.models.appointment import Appointment, AppointmentStatus, AppointmentType
from app.services.auth_service import get_password_hash

def seed():
    db = SessionLocal()
    try:
        print("Iniciando seed de dados reais para Sua Consulta...")

        # 1. Criar Médicos (Usuários e Perfis)
        doctors_to_create = [
            {
                "username": "ricardo.almeida",
                "email": "ricardo.almeida@suaconsulta.com",
                "full_name": "Dr. Ricardo Almeida",
                "especialidade": "Cardiologia",
                "crm": "111111",
                "crm_estado": "SP",
                "bio": "Especialista em cardiologia com mais de 15 anos de experiência.",
                "foto": "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=2070&auto=format&fit=crop"
            },
            {
                "username": "elena.costa",
                "email": "elena.costa@suaconsulta.com",
                "full_name": "Dra. Elena Costa",
                "especialidade": "Clínica Geral",
                "crm": "222222",
                "crm_estado": "SP",
                "bio": "Atendimento humanizado e focado em medicina preventiva.",
                "foto": "https://images.unsplash.com/photo-1594824476967-48c8b964273f?q=80&w=1974&auto=format&fit=crop"
            },
            {
                "username": "joao.santos",
                "email": "joao.santos@suaconsulta.com",
                "full_name": "Dr. João Santos",
                "especialidade": "Cardiologia",
                "crm": "333333",
                "crm_estado": "SP",
                "bio": "Especialista em exames diagnósticos e acompanhamento cardíaco.",
                "foto": "https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=2070&auto=format&fit=crop"
            },
            {
                "username": "maria.lima",
                "email": "maria.lima@suaconsulta.com",
                "full_name": "Dra. Maria Lima",
                "especialidade": "Dermatologia",
                "crm": "444444",
                "crm_estado": "SP",
                "bio": "Referência em dermatologia clínica e estética.",
                "foto": "https://images.unsplash.com/photo-1559839734-2b71f1536783?q=80&w=2070&auto=format&fit=crop"
            }
        ]

        created_doctors = []
        for doc_data in doctors_to_create:
            # Criar Usuário
            user = db.query(User).filter(User.username == doc_data["username"]).first()
            if not user:
                user = User(
                    username=doc_data["username"],
                    email=doc_data["email"],
                    full_name=doc_data["full_name"],
                    hashed_password=get_password_hash("senha123"),
                    role=UserRole.DOCTOR.value
                )
                db.add(user)
                db.commit()
                db.refresh(user)
                print(f"Usuário criado: {user.username}")
            
            # Criar Perfil Medico
            medico = db.query(Medico).filter(Medico.crm == doc_data["crm"]).first()
            if not medico:
                medico = Medico(
                    nome_completo=doc_data["full_name"],
                    crm=doc_data["crm"],
                    crm_estado=doc_data["crm_estado"],
                    especialidade=doc_data["especialidade"],
                    email=doc_data["email"],
                    bio_resumida=doc_data["bio"],
                    foto_url=doc_data["foto"],
                    user_id=user.id,
                    cidade="São Paulo",
                    endereco="Av. Paulista, 1500"
                )
                db.add(medico)
                print(f"Perfil Médico criado: {medico.nome_completo}")
            
            created_doctors.append({"user": user, "medico": medico})

        db.commit()

        # 2. Criar Paciente (Maria Silva)
        patient_user = db.query(User).filter(User.username == "maria.silva").first()
        if not patient_user:
            patient_user = User(
                username="maria.silva",
                email="maria.silva@email.com",
                full_name="Maria Silva",
                hashed_password=get_password_hash("senha123"),
                role=UserRole.PATIENT.value
            )
            db.add(patient_user)
            db.commit()
            db.refresh(patient_user)
            print(f"Usuário Paciente criado: {patient_user.username}")

        patient = db.query(Patient).filter(Patient.email == "maria.silva@email.com").first()
        if not patient:
            patient = Patient(
                name="Maria Silva",
                email="maria.silva@email.com",
                phone="5511988887777",
                whatsapp="5511988887777",
                gender=Gender.FEMALE.value,
                date_of_birth=datetime(1985, 3, 15),
                cpf="555.555.555-55",
                city="São Paulo",
                state="SP",
                notes="Tipo Sanguíneo: O+ | Alergias: Penicilina, Pólen | Condições Crônicas: Hipertensão | Medicamentos em Uso: Losartana 50mg",
                heart_rate="74",
                blood_pressure="12/8",
                glucose="98"
            )
            db.add(patient)
            print(f"Registro de Paciente criado: {patient.name}")
        else:
            # Atualizar dados se já existir
            patient.heart_rate = "74"
            patient.blood_pressure = "12/8"
            patient.glucose = "98"
            print(f"Registro de Paciente atualizado: {patient.name}")
        
        db.commit()
        db.refresh(patient)

        # 3. Criar Agendamentos para Maria Silva
        # Consulta com Dr. Ricardo Almeida (Amanhã)
        tomorrow = datetime.utcnow() + timedelta(days=1)
        tomorrow = tomorrow.replace(hour=14, minute=30, second=0, microsecond=0)
        
        existing_apt = db.query(Appointment).filter(
            Appointment.patient_id == patient.id,
            Appointment.medico_id == created_doctors[0]["medico"].id
        ).first()
        
        if not existing_apt:
            apt1 = Appointment(
                patient_id=patient.id,
                doctor_id=created_doctors[0]["user"].id,
                medico_id=created_doctors[0]["medico"].id,
                appointment_date=tomorrow,
                status=AppointmentStatus.CONFIRMED.value,
                type=AppointmentType.CONSULTATION.value,
                reason="Check-up cardiológico anual"
            )
            db.add(apt1)
            print(f"Agendamento criado: Maria Silva -> {created_doctors[0]['medico'].nome_completo}")

        # Consulta com Dra. Elena Costa (25 de Outubro - Simulado como data futura)
        future_date = datetime(2026, 10, 25, 10, 0)
        
        existing_apt2 = db.query(Appointment).filter(
            Appointment.patient_id == patient.id,
            Appointment.medico_id == created_doctors[1]["medico"].id
        ).first()
        
        if not existing_apt2:
            apt2 = Appointment(
                patient_id=patient.id,
                doctor_id=created_doctors[1]["user"].id,
                medico_id=created_doctors[1]["medico"].id,
                appointment_date=future_date,
                status=AppointmentStatus.CONFIRMED.value,
                type=AppointmentType.CONSULTATION.value,
                reason="Consulta de rotina - Clínica Geral"
            )
            db.add(apt2)
            print(f"Agendamento criado: Maria Silva -> {created_doctors[1]['medico'].nome_completo}")

        # 4. Criar Agendamentos Passados para aparecer no histórico
        past_date = datetime.utcnow() - timedelta(days=10)
        existing_apt3 = db.query(Appointment).filter(
            Appointment.patient_id == patient.id,
            Appointment.medico_id == created_doctors[2]["medico"].id,
            Appointment.status == AppointmentStatus.COMPLETED.value
        ).first()
        
        if not existing_apt3:
            apt3 = Appointment(
                patient_id=patient.id,
                doctor_id=created_doctors[2]["user"].id,
                medico_id=created_doctors[2]["medico"].id,
                appointment_date=past_date,
                status=AppointmentStatus.COMPLETED.value,
                type=AppointmentType.CONSULTATION.value,
                reason="Avaliação de estresse"
            )
            db.add(apt3)
            print(f"Agendamento PASSADO criado: Maria Silva -> {created_doctors[2]['medico'].nome_completo}")

        # 5. Criar Exame para Maria Silva
        from app.models.exam import Exam
        existing_exam = db.query(Exam).filter(Exam.patient_id == patient.id).first()
        if not existing_exam:
            exam = Exam(
                patient_id=patient.id,
                title="Hemograma Completo",
                exam_url="https://example.com/exam.pdf",
                summary="Resultados dentro da normalidade. Leve anemia observada.",
                created_at=datetime.utcnow() - timedelta(days=2)
            )
            db.add(exam)
            print(f"Exame criado para Maria Silva")

        db.commit()
        print("Seed finalizado com sucesso!")

    except Exception as e:
        print(f"Erro durante o seed: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
