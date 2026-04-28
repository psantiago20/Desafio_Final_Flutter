"""
seed_rag_test.py — Script de seed para testar o sistema RAG/Agent

Cria:
- Paciente João Silva (com CPF, WhatsApp)
- Médico Dr. Carlos Mendes (na tabela medicos, com CRM, especialidade, etc.)
- Um agendamento de teste entre os dois

Execute com: python -m seed_rag_test (de dentro da pasta backend/)
Ou via Docker: docker exec omniconnect-backend python seed_rag_test.py
"""

import hashlib
import json
from datetime import datetime, timedelta

from app.db.database import SessionLocal, engine, Base
from app.models.user import User
from app.models.patient import Patient
from app.models.medico import Medico
from app.models.appointment import Appointment

# Importar todos os models para criar as tabelas
from app.models import *


def seed():
    # Criar todas as tabelas (incluindo medicos)
    Base.metadata.create_all(bind=engine)
    print("✅ Tabelas criadas/verificadas")

    db = SessionLocal()

    try:
        # ------------------------------------------------------------ #
        #  1. PACIENTE JOÃO
        # ------------------------------------------------------------ #
        patient = db.query(Patient).filter(Patient.cpf == "123.456.789-00").first()
        if not patient:
            patient = Patient(
                name="João Silva",
                email="joao.silva@email.com",
                phone="5511987654321",
                whatsapp="5511987654321",
                date_of_birth=datetime(1990, 5, 15),
                gender="male",
                cpf="123.456.789-00",
                address="Rua das Flores, 100 - Apto 42",
                city="São Paulo",
                state="SP",
                cep="01001-000",
                insurance="Unimed",
                insurance_number="UNI-789456",
                preferencia_notificacao="whatsapp",
                is_active=True
            )
            db.add(patient)
            db.commit()
            db.refresh(patient)
            print(f"✅ Paciente criado: {patient.name} (ID: {patient.id})")
        else:
            print(f"ℹ️  Paciente já existe: {patient.name} (ID: {patient.id})")

        # ------------------------------------------------------------ #
        #  2. MÉDICO DR. CARLOS
        # ------------------------------------------------------------ #
        medico = db.query(Medico).filter(Medico.crm == "12345").first()
        if not medico:
            medico = Medico(
                nome_completo="Dr. Carlos Mendes",
                crm="12345",
                crm_estado="SP",
                cidade="São Paulo",
                endereco="Av. Paulista, 1000 - Conj 42",
                especialidade="Cardiologia",
                email="dr.carlos@omniconnect.com",
                telefone="5511912345678",
                whatsapp="5511912345678",
                whatsapp_phone_number_id="TEST_PHONE_ID_001",
                bio_resumida="Cardiologista com 15 anos de experiência. "
                             "Especialista em ecocardiografia e arritmias cardíacas. "
                             "Membro da Sociedade Brasileira de Cardiologia.",
                foto_url="",
                duracao_consulta_min=40,
                valor_consulta=280.00,
                aceita_convenio=True,
                convenios=json.dumps(["Unimed", "Bradesco Saúde", "SulAmérica", "Amil"]),
                ativo=True
            )
            db.add(medico)
            db.commit()
            db.refresh(medico)
            print(f"✅ Médico criado: {medico.nome_completo} (ID: {medico.id}, CRM: {medico.crm}/{medico.crm_estado})")
        else:
            print(f"ℹ️  Médico já existe: {medico.nome_completo} (ID: {medico.id})")

        # ------------------------------------------------------------ #
        #  3. USER (login no app) para o Dr. Carlos
        # ------------------------------------------------------------ #
        user_doctor = db.query(User).filter(User.username == "dr.carlos").first()
        if not user_doctor:
            password = b"carlos123"
            hashed = hashlib.sha256(password).hexdigest()
            user_doctor = User(
                username="dr.carlos",
                email="dr.carlos@omniconnect.com",
                hashed_password=hashed,
                full_name="Dr. Carlos Mendes",
                role="doctor",
                is_active=True
            )
            db.add(user_doctor)
            db.commit()
            db.refresh(user_doctor)

            # Vincular user ao medico
            medico.user_id = user_doctor.id
            db.commit()
            print(f"✅ User criado para Dr. Carlos (user_id: {user_doctor.id})")
        else:
            print(f"ℹ️  User dr.carlos já existe (ID: {user_doctor.id})")

        # ------------------------------------------------------------ #
        #  4. AGENDAMENTOS DE TESTE
        # ------------------------------------------------------------ #
        existing_appt = db.query(Appointment).filter(
            Appointment.patient_id == patient.id,
            Appointment.medico_id == medico.id
        ).first()

        if not existing_appt:
            # Agendamento futuro (daqui 3 dias)
            appt1 = Appointment(
                patient_id=patient.id,
                doctor_id=user_doctor.id if user_doctor else 1,
                medico_id=medico.id,
                appointment_date=datetime.utcnow() + timedelta(days=3, hours=14),
                duration_minutes=40,
                type="consultation",
                status="confirmed",
                reason="Check-up cardiológico anual",
                notes="Paciente com histórico familiar de hipertensão",
                canal_notificacao="whatsapp"
            )
            db.add(appt1)

            # Agendamento passado (5 dias atrás)
            appt2 = Appointment(
                patient_id=patient.id,
                doctor_id=user_doctor.id if user_doctor else 1,
                medico_id=medico.id,
                appointment_date=datetime.utcnow() - timedelta(days=5),
                duration_minutes=40,
                type="consultation",
                status="completed",
                reason="Dor no peito ao fazer exercícios",
                notes="ECG normal. Orientado sobre atividade física gradual.",
                canal_notificacao="whatsapp"
            )
            db.add(appt2)

            db.commit()
            print("✅ Agendamentos de teste criados (1 futuro, 1 passado)")
        else:
            print("ℹ️  Agendamentos de teste já existem")

        # ------------------------------------------------------------ #
        #  RESUMO
        # ------------------------------------------------------------ #
        print("\n" + "=" * 60)
        print("  DADOS DE TESTE PRONTOS")
        print("=" * 60)
        print(f"  Paciente: {patient.name}")
        print(f"    CPF: {patient.cpf}")
        print(f"    WhatsApp: {patient.whatsapp}")
        print(f"  Médico: {medico.nome_completo}")
        print(f"    CRM: {medico.crm}/{medico.crm_estado}")
        print(f"    Especialidade: {medico.especialidade}")
        print(f"    Medico ID: {medico.id}")
        print(f"    Phone Number ID: {medico.whatsapp_phone_number_id}")
        print("=" * 60)
        print("\n🧪 Para testar o agente:")
        print(f"  curl -X POST http://localhost:8000/api/rag/query \\")
        print(f'    -H "Content-Type: application/json" \\')
        print(f'    -d \'{{"query": "quais horários do Dr. Carlos?", "doctor_id": {medico.id}}}\'')
        print()

    finally:
        db.close()


if __name__ == "__main__":
    seed()
