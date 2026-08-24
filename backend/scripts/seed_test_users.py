
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
    db.execute(text("TRUNCATE TABLE doctor_profiles RESTART IDENTITY CASCADE")) # Legado, mantido para limpeza
    db.execute(text("TRUNCATE TABLE users RESTART IDENTITY CASCADE"))
    db.commit()

def seed_users(db: Session):
    print("Semeando usuários...")
    
    default_password = os.getenv("DEFAULT_PASSWORD", "senha123")
    admin_password = os.getenv("ADMIN_PASSWORD", "admin123")
    
    users_data = [
        # Admin master
        {
            "email": "admin@omniconnect.com",
            "username": "admin",
            "full_name": "Administrador do Sistema",
            "role": UserRole.ADMIN.value,
            "password": admin_password
                },
                # 4 Médicos
                {
                    "email": "marina.costa@suaconsulta.com",
                    "username": "marina.costa",
                    "full_name": "Dra. Marina Costa",
                    "role": UserRole.DOCTOR.value,
                    "password": default_password
                },
                {
                    "email": "thorne.blackwood@suaconsulta.com",
                    "username": "thorne.blackwood",
                    "full_name": "Dr. Thorne Blackwood",
                    "role": UserRole.DOCTOR.value,
                    "password": default_password
                },
                {
                    "email": "ana.costa@suaconsulta.com",
                    "username": "ana.costa",
                    "full_name": "Dra. Ana Costa",
                    "role": UserRole.DOCTOR.value,
                    "password": default_password
                },
                {
                    "email": "ricardo.mello@suaconsulta.com",
                    "username": "ricardo.mello",
                    "full_name": "Dr. Ricardo Mello",
                    "role": UserRole.DOCTOR.value,
                    "password": default_password
        }
    ]
    
    # Administradores adicionais
    # A lista de administradores e a senha correspondente são dinamicamente lidas a partir do .env
    admin_names_str = os.getenv("ADMIN_USERNAMES", "")
    admin_names = [name.strip() for name in admin_names_str.split(",") if name.strip()]
    for name in admin_names:
        users_data.append({
            "email": f"{name}@omniconnect.com",
            "username": name,
            "full_name": name.capitalize(),
            "role": UserRole.ADMIN.value,
            "password": name  # Senha dinâmica idêntica ao login
        })
    
    users = {}
    for u_data in users_data:
        user = User(
            email=u_data["email"],
            username=u_data["username"],
            full_name=u_data["full_name"],
            role=u_data["role"],
            hashed_password=get_password_hash(u_data["password"]),
            phone=u_data.get("phone"),
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
            "nome_completo": "Dra. Marina Costa",
            "crm": "123456",
            "crm_estado": "SP",
            "cidade": "São Paulo",
            "endereco": "Av. Paulista, 1000",
            "especialidade": "Clínica Geral",
            "email": "marina.costa@suaconsulta.com",
            "telefone": "5511911111111",
            "whatsapp": "5511911111111",
            "valor_consulta": 300.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Unimed", "Bradesco", "SulAmérica"]),
            "username": "marina.costa"
        },
        {
            "nome_completo": "Dr. Thorne Blackwood",
            "crm": "654321",
            "crm_estado": "RJ",
            "cidade": "Rio de Janeiro",
            "endereco": "Av. Atlântica, 200",
            "especialidade": "Cardiologia",
            "email": "thorne.blackwood@suaconsulta.com",
            "telefone": "5521922222222",
            "whatsapp": "5521922222222",
            "valor_consulta": 400.00,
            "aceita_convenio": False,
            "username": "thorne.blackwood"
        },
        {
            "nome_completo": "Dra. Ana Costa",
            "crm": "789123",
            "crm_estado": "SP",
            "cidade": "São Paulo",
            "endereco": "Rua Augusta, 500",
            "especialidade": "Dermatologia",
            "email": "ana.costa@suaconsulta.com",
            "telefone": "5511933333333",
            "whatsapp": "5511933333333",
            "valor_consulta": 350.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Amil", "SulAmérica"]),
            "username": "ana.costa"
        },
        {
            "nome_completo": "Dr. Ricardo Mello",
            "crm": "987654",
            "crm_estado": "SP",
            "cidade": "São Paulo",
            "endereco": "Praça da Sé, 100",
            "especialidade": "Neurologia",
            "email": "ricardo.mello@suaconsulta.com",
            "telefone": "5511944444444",
            "whatsapp": "5511944444444",
            "valor_consulta": 380.00,
            "aceita_convenio": True,
            "convenios": json.dumps(["Bradesco", "NotreDame"]),
            "username": "ricardo.mello"
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

def seed_patients(db: Session, users: dict):
    print("Semeando pacientes...")
    print("Nenhum paciente semeado por padrão (pacientes devem se cadastrar pela página inicial).")
    return []

import shutil

def seed_exams(db: Session, patients: list):
    print("Semeando exames reais...")
    if not patients:
        print("Nenhum paciente semeado. Pulando semeadura de exames de teste.")
        return
    
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
        # Distribuir os arquivos encontrados entre os pacientes e COPIAR
        summaries_dict = {
            "Hemograma Completo": "Anemia leve identificada (Hb: 11.5). Sugere-se investigação de ferritina.",
            "Eletrocardiograma (ECG)": "Os resultados estão dentro dos valores de referência.",
            "Raio-X de Tórax": "Os resultados estão dentro dos valores de referência.",
            "Exame de Urina tipo I": "Leucocitúria discreta. Possível infecção urinária inicial.",
            "Glicemia de Jejum": "Glicemia elevada (110 mg/dL). Solicitar Hemoglobina Glicada.",
            "Perfil Lipídico": "LDL elevado (160 mg/dL). Risco cardiovascular moderado.",
            "Ultrassom Abdominal": "Os resultados estão dentro dos valores de referência.",
            "Ressonância Magnética": "Hérnia de disco L4-L5 com compressão radicular leve.",
            "Tomografia Computadorizada": "Os resultados estão dentro dos valores de referência.",
            "Exame de Fezes": "Os resultados estão dentro dos valores de referência.",
            "TSH e T4 Livre": "TSH elevado (6.5). Sugere hipotireoidismo subclínico.",
            "Creatinina e Ureia": "Os resultados estão dentro dos valores de referência.",
            "Vitamina D": "Vitamina D baixa (18 ng/mL). Necessária suplementação.",
            "Ferritina": "Ferritina baixa (12 ng/mL). Estoques de ferro reduzidos.",
            "Ácido Úrico": "Hiperuricemia (8.2 mg/dL). Risco de gota. Dieta sugerida."
        }

        for i, file_name in enumerate(exam_files):
            patient = patients[i % len(patients)]
            
            # Usa o nome do arquivo (sem extensão) como título
            nome_exame = os.path.splitext(file_name)[0].replace('_', ' ').replace('-', ' ').title()
            
            src_path = os.path.join(exams_dir, file_name)
            dst_path = os.path.join(static_exams_dir, file_name)
            
            try:
                shutil.copy2(src_path, dst_path)
                
                # Tenta buscar um resumo conhecido, ou usa o padrão para resultados normais
                # se não houver um mapeamento específico.
                exam_summary = summaries_dict.get(nome_exame, "Os resultados estão dentro dos valores de referência.")

                exam = Exam(
                    patient_id=patient.id,
                    title=nome_exame,
                    exam_url=f"/static/exams/{file_name}",
                    summary=exam_summary
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
        patients = seed_patients(db, users)
        seed_exams(db, patients)
        
        # Adicionar agendamentos para hoje e para o futuro
        print("Semeando agendamentos de teste...")
        now = datetime.now()
        
        # Pega o primeiro médico como o principal para os testes do dashboard
        main_medico = list(medicos.values())[0]
        
        for i, p in enumerate(patients):
            m = main_medico # Vincula todos ao mesmo médico para ver no dashboard
            
            # 1. Agendamento para HOJE (horários variados)
            # Stagger times: 08:00, 09:00, 10:00, etc.
            apt_time = now.replace(hour=8 + i, minute=0, second=0, microsecond=0)
            
            apt_today = Appointment(
                patient_id=p.id,
                doctor_id=m.user_id,
                medico_id=m.id,
                appointment_date=apt_time,
                duration_minutes=30,
                status=AppointmentStatus.CONFIRMED.value if i > 0 else AppointmentStatus.COMPLETED.value,
                type=AppointmentType.CONSULTATION.value,
                reason=f"Consulta de rotina - {p.name}",
                price=m.valor_consulta,
                weight=p.weight,
                height=p.height,
                heart_rate=p.heart_rate,
                blood_pressure=p.blood_pressure,
                glucose=p.glucose,
                temperature=p.temperature
            )
            db.add(apt_today)
            
            # 2. Agendamento para daqui a 2 DIAS
            apt_future = Appointment(
                patient_id=p.id,
                doctor_id=m.user_id,
                medico_id=m.id,
                appointment_date=(now + timedelta(days=2)).replace(hour=14, minute=30, second=0, microsecond=0),
                duration_minutes=30,
                status=AppointmentStatus.CONFIRMED.value,
                type=AppointmentType.CONSULTATION.value,
                reason="Retorno programado",
                price=m.valor_consulta,
                weight=p.weight,
                height=p.height,
                heart_rate=p.heart_rate,
                blood_pressure=p.blood_pressure,
                glucose=p.glucose,
                temperature=p.temperature
            )
            db.add(apt_future)
            
            print(f"Agendamentos criados para {p.name} com {m.nome_completo} (Hoje e +2 dias).")
        
        db.commit()
        print("\nSemeação concluída com sucesso!")
        
    except Exception as e:
        print(f"Erro ao semear: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed()
