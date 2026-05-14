import sys
import os
sys.path.append('.')
from app.db.database import SessionLocal
from app.models.user import User, UserRole
from app.models.medico import Medico
from app.services.auth_service import get_password_hash

db = SessionLocal()
try:
    medico = db.query(Medico).filter(Medico.nome_completo.ilike('%Thorne Blackwood%')).first()
    if medico:
        if not medico.user_id:
            user = User(
                email="dr.thorne@omniconnect.com",
                username="dr.thorne",
                full_name="Dr. Thorne Blackwood",
                role=UserRole.DOCTOR.value,
                hashed_password=get_password_hash("senha123"),
                is_active=True
            )
            db.add(user)
            db.flush()
            
            medico.user_id = user.id
            medico.email = user.email
            db.commit()
            print("User dr.thorne created and linked to Medico.")
        else:
            user = db.query(User).filter(User.id == medico.user_id).first()
            user.hashed_password = get_password_hash("senha123")
            db.commit()
            print(f"User already existed. Password reset. Username: {user.username}")
    else:
        print("Medico not found.")
except Exception as e:
    db.rollback()
    print(e)
finally:
    db.close()
