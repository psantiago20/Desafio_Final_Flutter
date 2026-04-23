import hashlib
from app.db.database import SessionLocal
from app.models.user import User
from app.models.patient import Patient

def populate():
    db = SessionLocal()
    
    # Create extra users
    users_to_create = [
        {"username": "doutor", "email": "doctor@omniconnect.com", "role": "doctor", "full_name": "Dr. Lucas Silva"},
        {"username": "recepcao", "email": "frontdesk@omniconnect.com", "role": "recep", "full_name": "Maria Atendimento"}
    ]
    
    password = b"senha123"
    hashed = hashlib.sha256(password).hexdigest()
    
    for u_data in users_to_create:
        existing = db.query(User).filter(User.username == u_data["username"]).first()
        if not existing:
            u = User(
                username=u_data["username"],
                email=u_data["email"],
                role=u_data["role"],
                full_name=u_data["full_name"],
                hashed_password=hashed,
                is_active=True
            )
            db.add(u)
            print(f"User {u_data['username']} created.")
        else:
            print(f"User {u_data['username']} already exists.")
            
    # Create a test patient
    existing_patient = db.query(Patient).filter(Patient.whatsapp == "5511999999999").first()
    if not existing_patient:
        p = Patient(
            name="João Teste",
            email="joao@teste.com",
            phone="5511999999999",
            whatsapp="5511999999999",
            cpf="12345678901"
        )
        db.add(p)
        print("Test patient created.")
    else:
        print("Test patient already exists.")
        
    db.commit()
    db.close()

if __name__ == "__main__":
    populate()
