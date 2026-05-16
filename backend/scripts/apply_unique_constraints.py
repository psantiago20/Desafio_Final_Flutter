import sys
import os
from sqlalchemy import text

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from app.db.database import engine

def apply():
    print("Aplicando constraints de unicidade...")
    try:
        with engine.begin() as conn:
            # Drop if exists for idempotency if needed, but let's just try to add
            try:
                conn.execute(text("ALTER TABLE patients ADD CONSTRAINT patients_phone_unique UNIQUE (phone)"))
                print("  OK: Unique constraint em phone")
            except Exception as e:
                print(f"  Aviso/Erro phone: {e}")
                
            try:
                conn.execute(text("ALTER TABLE patients ADD CONSTRAINT patients_email_unique UNIQUE (email)"))
                print("  OK: Unique constraint em email")
            except Exception as e:
                print(f"  Aviso/Erro email: {e}")

            try:
                conn.execute(text("ALTER TABLE patients ADD CONSTRAINT patients_whatsapp_unique UNIQUE (whatsapp)"))
                print("  OK: Unique constraint em whatsapp")
            except Exception as e:
                print(f"  Aviso/Erro whatsapp: {e}")
                
        print("\nProcesso concluído.")
    except Exception as e:
        print(f"Erro geral: {e}")

if __name__ == "__main__":
    apply()
