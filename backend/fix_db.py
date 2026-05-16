import sys
import os
sys.path.append('.')
from app.db.database import SessionLocal
from app.models.appointment import Appointment

def main():
    db = SessionLocal()
    try:
        appointments_to_delete = db.query(Appointment).filter(Appointment.status == 'cancelled').all()
        for app in appointments_to_delete:
            db.delete(app)
        
        appointments_to_confirm = db.query(Appointment).filter(Appointment.status == 'pending').all()
        for app in appointments_to_confirm:
            app.status = 'confirmed'
            
        db.commit()
        print(f"Deleted {len(appointments_to_delete)} cancelled appointments.")
        print(f"Confirmed {len(appointments_to_confirm)} pending appointments.")
    except Exception as e:
        db.rollback()
        print(e)
    finally:
        db.close()

if __name__ == '__main__':
    main()
