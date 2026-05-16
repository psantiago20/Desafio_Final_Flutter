import sys
import os
from sqlalchemy import text

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine

def migrate():
    print("Adicionando colunas de verificação na tabela users...")
    
    columns = [
        ("is_verified", "BOOLEAN DEFAULT FALSE"),
        ("verification_code", "VARCHAR(10)"),
        ("verification_code_expires_at", "TIMESTAMP")
    ]
    
    for col_name, col_type in columns:
        try:
            with engine.begin() as conn:
                conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
            print(f"Coluna {col_name} adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar {col_name} (pode já existir): {e}")
            
    print("Migração concluída.")

if __name__ == "__main__":
    migrate()
