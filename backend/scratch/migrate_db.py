import psycopg2
from app.core.config import settings

def migrate():
    try:
        conn = psycopg2.connect("postgresql://postgres:P2706303-2p@localhost:5432/omniconnect")
        cur = conn.cursor()
        
        print("Checking for missing columns in 'patients'...")
        
        # Add 'cep' if missing
        try:
            cur.execute("ALTER TABLE patients ADD COLUMN cep VARCHAR(10);")
            print("Column 'cep' added.")
        except Exception as e:
            conn.rollback()
            print(f"Column 'cep' might already exist or error: {e}")
            
        # Add 'preferencia_notificacao' if missing
        try:
            cur.execute("ALTER TABLE patients ADD COLUMN preferencia_notificacao VARCHAR(50) DEFAULT 'whatsapp';")
            print("Column 'preferencia_notificacao' added.")
        except Exception as e:
            conn.rollback()
            print(f"Column 'preferencia_notificacao' might already exist or error: {e}")
            
        conn.commit()
        cur.close()
        conn.close()
        print("Migration completed.")
    except Exception as e:
        print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
