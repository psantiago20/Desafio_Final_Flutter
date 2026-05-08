import sys
import os
from sqlalchemy import text

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine

def migrate():
    with engine.connect() as conn:
        print("Adicionando colunas de verificação na tabela users...")
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE"))
            print("Coluna is_verified adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar is_verified: {e}")
            
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN verification_code VARCHAR(10)"))
            print("Coluna verification_code adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar verification_code: {e}")

        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN verification_code_expires_at TIMESTAMP"))
            print("Coluna verification_code_expires_at adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar verification_code_expires_at: {e}")
        
        conn.commit()
        print("Migração concluída.")

if __name__ == "__main__":
    migrate()
