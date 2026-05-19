import sys
from sqlalchemy import create_engine, text
from app.models import User, Patient, Appointment, Message, Service, Medico, DoctorProfile, Exam
from app.db.database import Base
from app.core.config import settings

DATABASE_URL = settings.DATABASE_URL

engine = create_engine(DATABASE_URL)

def run_migrations():
    """
    Tenta adicionar colunas que podem estar faltando em instalações antigas
    sem usar ferramentas complexas de migração como Alembic.
    """
    print("Verificando colunas ausentes (Migrações automáticas)...")
    with engine.begin() as conn:
        # Colunas para adicionar na tabela patients
        patient_cols = [
            ("heart_rate", "VARCHAR(10)"),
            ("blood_pressure", "VARCHAR(20)"),
            ("glucose", "VARCHAR(10)"),
            ("temperature", "VARCHAR(10)"),
            ("weight", "VARCHAR(10)"),
            ("height", "VARCHAR(10)"),
            ("blood_type", "VARCHAR(5)"),
            ("allergies", "TEXT"),
            ("chronic_conditions", "TEXT"),
            ("medications", "TEXT"),
            ("cep", "VARCHAR(10)"),
            ("preferencia_notificacao", "VARCHAR(50)")
        ]
        
        for col, col_type in patient_cols:
            try:
                conn.execute(text(f"ALTER TABLE patients ADD COLUMN {col} {col_type}"))
                print(f"Coluna {col} adicionada à tabela patients.")
            except Exception:
                # Provavelmente a coluna já existe, ignoramos o erro
                pass
        
        # Colunas para adicionar na tabela appointments
        try:
            conn.execute(text("ALTER TABLE appointments ADD COLUMN medico_id INTEGER REFERENCES medicos(id)"))
            print("Coluna medico_id adicionada à tabela appointments.")
        except Exception:
            pass

def main():
    print(f"Conectando ao banco em: {DATABASE_URL.split('@')[-1]}")
    
    # 1. Cria tabelas que não existem
    print("Criando tabelas inexistentes...")
    Base.metadata.create_all(bind=engine)
    
    # 2. Adiciona colunas em tabelas que já existiam (migração manual leve)
    run_migrations()
    
    print('✅ Inicialização/Migração do banco de dados concluída com sucesso.')

if __name__ == "__main__":
    main()