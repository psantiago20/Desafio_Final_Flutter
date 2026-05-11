import os
import sys
from sqlalchemy.orm import Session
from sqlalchemy import create_engine
from dotenv import load_dotenv

# Adicionar o path do backend
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.database import SessionLocal
from app.models.patient import Patient

def check_patient(email):
    db = SessionLocal()
    try:
        patient = db.query(Patient).filter(Patient.email == email).first()
        if patient:
            print(f"Paciente: {patient.name}")
            print(f"Email: {patient.email}")
            print(f"Vitals -> Heart Rate: {patient.heart_rate}, BP: {patient.blood_pressure}, Glucose: {patient.glucose}")
        else:
            print("Paciente não encontrado.")
    finally:
        db.close()

if __name__ == "__main__":
    check_patient("maria.silva@email.com")
