"""
Migracao: Adiciona colunas de sinais vitais e saude na tabela patients.
Erro: coluna patients.temperature nao existe
"""
import sys
import os
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.db.database import engine


def migrate():
    print("Adicionando colunas na tabela patients...")

    columns = [
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
        ("cep",                 "VARCHAR(10)"),
        ("preferencia_notificacao", "VARCHAR(50) DEFAULT 'whatsapp'"),
        ("notes",               "TEXT"),
        ("tags",                "TEXT"),
        ("insurance",           "VARCHAR(100)"),
        ("insurance_number",    "VARCHAR(50)"),
        ("rg",                  "VARCHAR(20)"),
        ("cpf",                 "VARCHAR(14)"),
        ("state",               "VARCHAR(50)"),
        ("city",                "VARCHAR(100)"),
        ("address",             "VARCHAR(300)"),
        ("gender",              "VARCHAR(20)"),
        ("whatsapp",            "VARCHAR(20)"),
        ("user_id",             "INTEGER REFERENCES users(id)"),
    ]

    for col_name, col_type in columns:
        try:
            with engine.begin() as conn:
                conn.execute(
                    text(f"ALTER TABLE patients ADD COLUMN IF NOT EXISTS {col_name} {col_type}")
                )
            print(f"  OK: {col_name}")
        except Exception as e:
            print(f"  ERRO {col_name}: {e}")

    print("\nMigracao da tabela patients concluida.")


if __name__ == "__main__":
    migrate()
