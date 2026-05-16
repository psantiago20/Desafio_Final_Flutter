import sys
import os
from sqlalchemy import text

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine

def migrate():
    print("Adicionando colunas de sinais vitais na tabela patients...")
    
    columns = [
        ("heart_rate", "VARCHAR(10)"),
        ("blood_pressure", "VARCHAR(20)"),
        ("glucose", "VARCHAR(10)")
    ]
    
    for col_name, col_type in columns:
        try:
            with engine.begin() as conn:
                conn.execute(text(f"ALTER TABLE patients ADD COLUMN {col_name} {col_type}"))
            print(f"Coluna {col_name} adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar {col_name} (pode já existir): {e}")
            
    print("Migração concluída.")

if __name__ == "__main__":
    migrate()
