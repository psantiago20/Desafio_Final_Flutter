"""
Migração: Adiciona colunas de sinais vitais e campos clínicos na tabela appointments.
Erro: coluna appointments.weight não existe
"""
import sys
import os
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine


def migrate():
    print("Adicionando colunas de sinais vitais na tabela appointments...")

    columns = [
        ("weight",          "VARCHAR(20)"),
        ("height",          "VARCHAR(20)"),
        ("heart_rate",      "VARCHAR(20)"),
        ("blood_pressure",  "VARCHAR(20)"),
        ("glucose",         "VARCHAR(20)"),
        ("temperature",     "VARCHAR(20)"),
        # garantir que exam_summary também existe
        ("exam_summary",    "TEXT"),
    ]

    for col_name, col_type in columns:
        try:
            with engine.begin() as conn:
                conn.execute(
                    text(f"ALTER TABLE appointments ADD COLUMN IF NOT EXISTS {col_name} {col_type}")
                )
            print(f"  ✓ {col_name} OK")
        except Exception as e:
            print(f"  ! {col_name}: {e}")

    print("\nMigração concluída.")


if __name__ == "__main__":
    migrate()
