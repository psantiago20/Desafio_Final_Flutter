import sys
import os
from sqlalchemy import text

# Adiciona o diretório raiz ao path para poder importar o módulo app
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import engine

def migrate():
    with engine.connect() as conn:
        print("Adicionando colunas de sinais vitais na tabela patients...")
        
        # heart_rate = Column(String(10))
        try:
            conn.execute(text("ALTER TABLE patients ADD COLUMN heart_rate VARCHAR(10)"))
            print("Coluna heart_rate adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar heart_rate: {e}")
            
        # blood_pressure = Column(String(20))
        try:
            conn.execute(text("ALTER TABLE patients ADD COLUMN blood_pressure VARCHAR(20)"))
            print("Coluna blood_pressure adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar blood_pressure: {e}")

        # glucose = Column(String(10))
        try:
            conn.execute(text("ALTER TABLE patients ADD COLUMN glucose VARCHAR(10)"))
            print("Coluna glucose adicionada.")
        except Exception as e:
            print(f"Erro ao adicionar glucose: {e}")
        
        conn.commit()
        print("Migração concluída.")

if __name__ == "__main__":
    migrate()
