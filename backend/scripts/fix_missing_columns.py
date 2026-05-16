import sys
import os
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.db.database import engine

def migrate():
    print("Corrigindo banco de dados (PostgreSQL)...")

    # 1. Tabela Exams
    print("\nVerificando tabela 'exams'...")
    try:
        with engine.begin() as conn:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS exams (
                    id SERIAL PRIMARY KEY,
                    patient_id INTEGER NOT NULL REFERENCES patients(id),
                    title VARCHAR(200) DEFAULT 'Exame Médico',
                    exam_url VARCHAR(512) NOT NULL,
                    summary TEXT,
                    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
                )
            """))
        print("  OK: Tabela 'exams' verificada/criada.")
    except Exception as e:
        print(f"  ERRO ao criar tabela 'exams': {e}")

    # 2. Colunas faltantes em Appointments
    print("\nAdicionando colunas na tabela 'appointments'...")
    appointment_columns = [
        ("prescription_html", "TEXT"),
        ("exam_url",          "VARCHAR(255)"),
        ("exam_summary",      "TEXT"),
        ("weight",            "VARCHAR(20)"),
        ("height",            "VARCHAR(20)"),
        ("heart_rate",        "VARCHAR(20)"),
        ("blood_pressure",    "VARCHAR(20)"),
        ("glucose",           "VARCHAR(20)"),
        ("temperature",       "VARCHAR(20)"),
    ]

    for col_name, col_type in appointment_columns:
        try:
            with engine.begin() as conn:
                # IF NOT EXISTS é suportado no Postgres para ADD COLUMN? 
                # Não diretamente no ALTER TABLE sem extensões ou blocos anônimos em versões antigas,
                # mas vamos tentar a forma mais compatível.
                conn.execute(text(f"ALTER TABLE appointments ADD COLUMN IF NOT EXISTS {col_name} {col_type}"))
            print(f"  OK: appointments.{col_name}")
        except Exception as e:
            print(f"  ERRO appointments.{col_name}: {e}")

    # 3. Colunas faltantes em Patients (reforço)
    print("\nAdicionando colunas na tabela 'patients'...")
    patient_columns = [
        ("heart_rate",          "VARCHAR(10)"),
        ("blood_pressure",      "VARCHAR(20)"),
        ("glucose",             "VARCHAR(10)"),
        ("temperature",         "VARCHAR(10)"),
        ("weight",              "VARCHAR(10)"),
        ("height",              "VARCHAR(10)"),
        ("blood_type",          "VARCHAR(5)"),
        ("allergies",           "TEXT"),
        ("chronic_conditions",  "TEXT"),
        ("medications",         "TEXT"),
    ]

    for col_name, col_type in patient_columns:
        try:
            with engine.begin() as conn:
                conn.execute(text(f"ALTER TABLE patients ADD COLUMN IF NOT EXISTS {col_name} {col_type}"))
            print(f"  OK: patients.{col_name}")
        except Exception as e:
            print(f"  ERRO patients.{col_name}: {e}")

    print("\nMigração concluída.")

if __name__ == "__main__":
    migrate()
