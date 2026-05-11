
import sys
import os
import json
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from sqlalchemy import text

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal, engine, Base
from app.models.user import User, UserRole
from app.models.medico import Medico
from app.models.patient import Patient, Gender
from app.models.appointment import Appointment, AppointmentStatus, AppointmentType
from app.models.service import Service, ServiceStatus
from app.models.exam import Exam
from app.services.auth_service import get_password_hash

def clear_db(db: Session):
    print("Limpando banco de dados...")
    db.execute(text("TRUNCATE TABLE messages RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE exams RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE services RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE appointments RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE medicos RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE patients RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE doctor_profiles RESTART IDENTITY CASCADE"))
    db.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE"))
    db.commit()

def seed_users(db: Session):
    print("Semeando usuários...")
    
    users_data = [
        {
            "email": "admin@omniconnect.com",
            "username": "admin",
            "full_name": "Administrador do Sistema",
            "role": UserRole.ADMIN.value,
            "password": "admin123"
        },
        {
            "email": "dr.carlos@omniconnect.com",
            "username": "dr.carlos",
            "full_name": "Dr. Carlos Mendes",
            "role": UserRole.DOCTOR.value,
            "password": "senha123"
        },
        {
            "email": "dra.maria@omniconnect.com",
            "username": "dra.maria",
            "full_name": "Dra. Maria Oliveira",
            "role": UserRole.DOCTOR.value,
            "password": "senha123"
        },
        {
            "email": "joao.silva@email.com",
            "username": "joao.silva",
            "full_name": "João Silva",
            "role": UserRole.PATIENT.value,
            "password": "senha123"
        }
    ]
    
    users = {}
    for u_data in users_data:
        user = User(
            email=u_data["email"],
            username=u_data["username"],
            full_name=u_data["full_name"],
            role=u_data["role"],
            hashed_password=get_password_hash(u_data["password"]),
            is_active=True
        )
        db.add(user)
        db.flush()
        users[u_data["username"]] = user
        print(f"Usuário {u_data['username']} criado.")
    
    db.commit()
    return users

def seed_medicos(db: Session, users: dict):
    print("Semeando perfis médicos...")
    
    medicos_data = [
        {
            "nome_completo": "Dr. Carlos Mendes",
            "crm": "12345",
            "crm_estado": "SP",
            "cidade": "São Paulo",
            "endereco": "Av. Paulista, 1000 - Conj 42",
            "especialidade": "Cardiologia",
            "email": "dr.carlos@omniconnect.com",
            "telefone": "5511912345678",
            "whatsapp": "5511912345678",
            "whatsapp_phone_number_id": "WA_ID_CARLOS",
            "bio_resumida": "Cardiologista com 15 anos de experiência. Especialista em ecocardiografia e arritmias cardíacas.",
            "valor_consulta": 280.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Unimed", "Bradesco Saúde", "SulAmérica"]),
            "username": "dr.carlos"
        },
        {
            "nome_completo": "Dra. Maria Oliveira",
            "crm": "54321",
            "crm_estado": "SP",
            "cidade": "Campinas",
            "endereco": "Av. Brasil, 500 - Sala 10",
            "especialidade": "Dermatologia",
            "email": "dra.maria@omniconnect.com",
            "telefone": "5511922223333",
            "whatsapp": "5511922223333",
            "whatsapp_phone_number_id": "WA_ID_MARIA",
            "bio_resumida": "Dermatologista com foco em estética e saúde da pele. Especialista em tratamentos a laser.",
            "valor_consulta": 350.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Unimed", "Amil"]),
            "username": "dra.maria"
        }
    ]
    
    medicos = {}
    for m_data in medicos_data:
        username = m_data.pop("username")
        medico = Medico(**m_data, user_id=users[username].id)
        db.add(medico)
        db.flush()
        medicos[medico.nome_completo] = medico
        print(f"Perfil médico {medico.nome_completo} criado.")
        
    db.commit()
    return medicos

def seed_patients(db: Session):
    print("Semeando pacientes...")
    
    patients_data = [
        {
            "name": "João Silva",
            "email": "joao.silva@email.com",
            "phone": "5511987654321",
            "whatsapp": "5511987654321",
            "date_of_birth": datetime(1990, 5, 15),
            "gender": Gender.MALE.value,
            "cpf": "123.456.789-00",
            "city": "São Paulo",
            "state": "SP",
            "insurance": "Unimed",
            "notes": "Histórico de asma na infância."
        },
        {
            "name": "Maria Silva",
            "email": "maria.silva@email.com",
            "phone": "5511988887777",
            "whatsapp": "5511988887777",
            "gender": Gender.FEMALE.value,
            "date_of_birth": datetime(1985, 3, 15),
            "cpf": "555.555.555-55",
            "city": "São Paulo",
            "state": "SP",
            "notes": "Alergia a Penicilina."
        },
        {
            "name": "Pedro Santiago",
            "cpf": "123.456.789-11",
            "phone": "5511988888888",
            "whatsapp": "5511988888888",
            "city": "São Paulo",
            "state": "SP",
            "insurance": "Bradesco"
        }
    ]
    
    patients = []
    for p_data in patients_data:
        patient = Patient(**p_data)
        db.add(patient)
        db.flush()
        patients.append(patient)
        print(f"Paciente {patient.name} criado.")
        
    db.commit()
    return patients

def seed_appointments(db: Session, medicos: dict, patients: list, users: dict):
    print("Semeando agendamentos...")
    
    # 1. João com Dr. Carlos (Passado)
    apt1 = Appointment(
        patient_id=patients[0].id,
        doctor_id=users["dr.carlos"].id,
        medico_id=medicos["Dr. Carlos Mendes"].id,
        appointment_date=datetime.utcnow() - timedelta(days=5, hours=2),
        duration_minutes=40,
        type=AppointmentType.CONSULTATION.value,
        status=AppointmentStatus.COMPLETED.value,
        reason="Check-up cardiológico",
        price=280.00,
        paid=True,
        payment_method="PIX"
    )
    db.add(apt1)
    
    # 2. João com Dr. Carlos (Futuro)
    apt2 = Appointment(
        patient_id=patients[0].id,
        doctor_id=users["dr.carlos"].id,
        medico_id=medicos["Dr. Carlos Mendes"].id,
        appointment_date=datetime.utcnow() + timedelta(days=3, hours=4),
        duration_minutes=40,
        type=AppointmentType.RETURN.value,
        status=AppointmentStatus.CONFIRMED.value,
        reason="Retorno para ver exames",
        price=0.0,
        paid=True
    )
    db.add(apt2)
    
    # 3. Maria com Dra. Maria (Futuro)
    apt3 = Appointment(
        patient_id=patients[1].id,
        doctor_id=users["dra.maria"].id,
        medico_id=medicos["Dra. Maria Oliveira"].id,
        appointment_date=datetime.utcnow() + timedelta(days=1, hours=1),
        duration_minutes=30,
        type=AppointmentType.CONSULTATION.value,
        status=AppointmentStatus.CONFIRMED.value,
        reason="Avaliação de manchas na pele",
        price=350.00,
        paid=False
    )
    db.add(apt3)
    
    db.commit()
    return [apt1, apt2, apt3]

def seed_services(db: Session, patients: list, appointments: list):
    print("Semeando serviços...")
    
    services_data = [
        {
            "patient_id": patients[0].id,
            "appointment_id": appointments[0].id,
            "name": "Exame de Sangue Completo",
            "description": "Hemograma, Glicemia, Colesterol",
            "category": "Laboratorial",
            "status": ServiceStatus.COMPLETED.value,
            "priority": "normal",
            "price": 120.00,
            "cost": 50.00,
            "ai_suggestion": "Sugerido pelo assistente após queixa de cansaço."
        },
        {
            "patient_id": patients[0].id,
            "appointment_id": appointments[1].id,
            "name": "Eletrocardiograma",
            "description": "ECG de repouso",
            "category": "Cardíaco",
            "status": ServiceStatus.PENDING.value,
            "priority": "alta",
            "price": 80.00,
            "cost": 30.00
        },
        {
            "patient_id": patients[1].id,
            "appointment_id": appointments[2].id,
            "name": "Biópsia de Pele",
            "description": "Retirada de pequena amostra para análise",
            "category": "Procedimento",
            "status": ServiceStatus.PENDING.value,
            "priority": "normal",
            "price": 450.00,
            "cost": 150.00
        }
    ]
    
    for s_data in services_data:
        service = Service(**s_data)
        db.add(service)
        print(f"Serviço {service.name} criado.")
        
    db.commit()

def seed_exams(db: Session, patients: list):
    print("Semeando exames...")
    
    exams_data = [
        {
            "patient_id": patients[0].id,
            "title": "Hemograma Completo",
            "exam_url": "https://exemplo.com/exames/hemograma_joao.pdf",
            "summary": "Resultados dentro da normalidade, leve anemia detectada."
        },
        {
            "patient_id": patients[0].id,
            "title": "Eletrocardiograma",
            "exam_url": "https://exemplo.com/exames/ecg_joao.pdf",
            "summary": "Ritmo sinusal normal."
        }
    ]
    
    for e_data in exams_data:
        exam = Exam(**e_data)
        db.add(exam)
        print(f"Exame {exam.title} criado.")
        
    db.commit()

def seed():
    db = SessionLocal()
    try:
        clear_db(db)
        users = seed_users(db)
        medicos = seed_medicos(db, users)
        patients = seed_patients(db)
        appointments = seed_appointments(db, medicos, patients, users)
        seed_services(db, patients, appointments)
        seed_exams(db, patients)
        
        print("\nSemeação concluída com sucesso!")
        print("-" * 30)
        print("Logins disponíveis:")
        print("ADMIN: admin / admin123")
        print("MÉDICO 1: dr.carlos / senha123")
        print("MÉDICO 2: dra.maria / senha123")
        print("PACIENTE: joao.silva / senha123")
        print("-" * 30)
        
    except Exception as e:
        print(f"Erro ao semear: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
