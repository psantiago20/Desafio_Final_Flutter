
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
        # Admin
        {
            "email": "admin@omniconnect.com",
            "username": "admin",
            "full_name": "Administrador do Sistema",
            "role": UserRole.ADMIN.value,
            "password": "admin123"
        },
        # 4 Médicos
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
            "email": "dr.roberto@omniconnect.com",
            "username": "dr.roberto",
            "full_name": "Dr. Roberto Santos",
            "role": UserRole.DOCTOR.value,
            "password": "senha123"
        },
        {
            "email": "dra.julia@omniconnect.com",
            "username": "dra.julia",
            "full_name": "Dra. Julia Costa",
            "role": UserRole.DOCTOR.value,
            "password": "senha123"
        },
        # 4 Pacientes
        {
            "email": "joao.silva@email.com",
            "username": "joao.silva",
            "full_name": "João Silva",
            "role": UserRole.PATIENT.value,
            "password": "senha123"
        },
        {
            "email": "ana.souza@email.com",
            "username": "ana.souza",
            "full_name": "Ana Souza",
            "role": UserRole.PATIENT.value,
            "password": "senha123"
        },
        {
            "email": "pedro.santiago@email.com",
            "username": "pedro.santiago",
            "full_name": "Pedro Santiago",
            "role": UserRole.PATIENT.value,
            "password": "senha123"
        },
        {
            "email": "carla.ferreira@email.com",
            "username": "carla.ferreira",
            "full_name": "Carla Ferreira",
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
            "endereco": "Av. Paulista, 1000",
            "especialidade": "Cardiologia",
            "email": "dr.carlos@omniconnect.com",
            "telefone": "5511911111111",
            "whatsapp": "5511911111111",
            "valor_consulta": 300.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Unimed", "Bradesco"]),
            "username": "dr.carlos"
        },
        {
            "nome_completo": "Dra. Maria Oliveira",
            "crm": "54321",
            "crm_estado": "SP",
            "cidade": "São Paulo",
            "endereco": "Rua Augusta, 500",
            "especialidade": "Dermatologia",
            "email": "dra.maria@omniconnect.com",
            "telefone": "5511922222222",
            "whatsapp": "5511922222222",
            "valor_consulta": 350.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Amil", "SulAmérica"]),
            "username": "dra.maria"
        },
        {
            "nome_completo": "Dr. Roberto Santos",
            "crm": "98765",
            "crm_estado": "RJ",
            "cidade": "Rio de Janeiro",
            "endereco": "Av. Atlântica, 200",
            "especialidade": "Ortopedia",
            "email": "dr.roberto@omniconnect.com",
            "telefone": "5521933333333",
            "whatsapp": "5521933333333",
            "valor_consulta": 250.00,
            "aceita_convenio": False,
            "username": "dr.roberto"
        },
        {
            "nome_completo": "Dra. Julia Costa",
            "crm": "65432",
            "crm_estado": "MG",
            "cidade": "Belo Horizonte",
            "endereco": "Praça da Liberdade, 10",
            "especialidade": "Pediatria",
            "email": "dra.julia@omniconnect.com",
            "telefone": "5531944444444",
            "whatsapp": "5531944444444",
            "valor_consulta": 280.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Unimed", "Allianz"]),
            "username": "dra.julia"
        }
    ]
    
    medicos = {}
    for m_data in medicos_data:
        username = m_data.pop("username")
        medico = Medico(**m_data, user_id=users[username].id)
        db.add(medico)
        db.flush()
        medicos[medico.nome_completo] = medico
        print(f"Médico {medico.nome_completo} criado.")
        
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
            "insurance": "Unimed"
        },
        {
            "name": "Ana Souza",
            "email": "ana.souza@email.com",
            "phone": "5511999998888",
            "whatsapp": "5511999998888",
            "date_of_birth": datetime(1985, 8, 20),
            "gender": Gender.FEMALE.value,
            "cpf": "222.222.222-22",
            "city": "São Paulo",
            "state": "SP",
            "insurance": "Bradesco"
        },
        {
            "name": "Pedro Santiago",
            "email": "pedro.santiago@email.com",
            "phone": "5511977776666",
            "whatsapp": "5511977776666",
            "date_of_birth": datetime(1995, 12, 10),
            "gender": Gender.MALE.value,
            "cpf": "333.333.333-33",
            "city": "São Paulo",
            "state": "SP"
        },
        {
            "name": "Carla Ferreira",
            "email": "carla.ferreira@email.com",
            "phone": "5511966665555",
            "whatsapp": "5511966665555",
            "date_of_birth": datetime(1982, 2, 28),
            "gender": Gender.FEMALE.value,
            "cpf": "444.444.444-44",
            "city": "São Paulo",
            "state": "SP",
            "insurance": "SulAmérica"
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

import shutil

def seed_exams(db: Session, patients: list):
    print("Semeando exames reais...")
    
    # Pasta de origem
    exams_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "exames-teste")
    
    # Pasta de destino (onde o servidor serve arquivos estáticos)
    static_exams_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "static", "exams")
    
    # Criar a pasta de destino se não existir
    if not os.path.exists(static_exams_dir):
        os.makedirs(static_exams_dir)
        print(f"Pasta de destino criada: {static_exams_dir}")
    
    if not os.path.exists(exams_dir):
        os.makedirs(exams_dir)
        print(f"Aviso: Pasta de origem {exams_dir} não existia e foi criada vazia.")
    
    exam_files = [f for f in os.listdir(exams_dir) if os.path.isfile(os.path.join(exams_dir, f))]
    
    if not exam_files:
        print("Nenhum arquivo encontrado em exames-teste. Semeando registros de exemplo.")
        for i, patient in enumerate(patients):
            exam = Exam(
                patient_id=patient.id,
                title=f"Check-up Anual - {patient.name}",
                exam_url="https://exemplo.com/exam_padrao.pdf",
                summary="Exame de rotina (Arquivo não encontrado na pasta de origem)."
            )
            db.add(exam)
    else:
        # Nomes de exames realistas para deixar o app bonito
        nomes_exames = [
            "Hemograma Completo", "Eletrocardiograma (ECG)", "Raio-X de Tórax", 
            "Exame de Urina tipo I", "Glicemia de Jejum", "Perfil Lipídico", 
            "Ultrassom Abdominal", "Ressonância Magnética", "Tomografia Computadorizada",
            "Exame de Fezes", "TSH e T4 Livre", "Creatinina e Ureia",
            "Vitamina D", "Ferritina", "Ácido Úrico"
        ]
        
        # Distribuir os arquivos encontrados entre os pacientes e COPIAR
        for i, file_name in enumerate(exam_files):
            patient = patients[i % len(patients)]
            nome_exame = nomes_exames[i % len(nomes_exames)] # Escolhe um nome da lista
            
            src_path = os.path.join(exams_dir, file_name)
            dst_path = os.path.join(static_exams_dir, file_name)
            
            try:
                shutil.copy2(src_path, dst_path)
                
                exam = Exam(
                    patient_id=patient.id,
                    title=nome_exame, # Agora usa o nome real em vez do nome do arquivo
                    exam_url=f"/static/exams/{file_name}",
                    summary=f"Exame de {nome_exame.lower()} importado para o sistema."
                )
                db.add(exam)
                print(f"Exame '{nome_exame}' atribuído a {patient.name}.")
            except Exception as e:
                print(f"Erro ao copiar arquivo {file_name}: {e}")
    
    db.commit()

def seed():
    db = SessionLocal()
    try:
        clear_db(db)
        users = seed_users(db)
        medicos = seed_medicos(db, users)
        patients = seed_patients(db)
        seed_exams(db, patients)
        
        # Adicionar alguns agendamentos para não ficar vazio
        print("Semeando agendamentos de teste...")
        for i, p in enumerate(patients):
            m_list = list(medicos.values())
            m = m_list[i % len(m_list)]
            apt = Appointment(
                patient_id=p.id,
                doctor_id=m.user_id,
                medico_id=m.id,
                appointment_date=datetime.now() + timedelta(days=i+1, hours=10),
                duration_minutes=30,
                status=AppointmentStatus.CONFIRMED.value,
                type=AppointmentType.CONSULTATION.value,
                reason="Consulta de rotina",
                price=m.valor_consulta
            )
            db.add(apt)
        
        db.commit()
        print("\nSemeação concluída com sucesso!")
        
    except Exception as e:
        print(f"Erro ao semear: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
