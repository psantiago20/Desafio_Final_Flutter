import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.models.user import User
from app.models.patient import Patient

def list_users_patients():
    db = SessionLocal()
    try:
        users = db.query(User).all()
        print("=== USERS ===")
        for u in users:
            print(f"ID: {u.id} | Username: {u.username} | Role: {u.role} | Full Name: {u.full_name}")
            
        patients = db.query(Patient).all()
        print("\n=== PATIENTS ===")
        for p in patients:
            print(f"ID: {p.id} | UserID: {p.user_id} | Name: {p.name} | Phone: {p.phone}")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    list_users_patients()
