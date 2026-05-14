import sys
import os
sys.path.append(os.getcwd())
from app.db.database import SessionLocal
from app.models.user import User, UserRole
from app.models.medico import Medico
from app.services.auth_service import get_password_hash

def fix_ana():
    db = SessionLocal()
    try:
        ana = db.query(User).filter(User.username == 'ana.costa').first()
        if not ana:
            print("Criando Dra. Ana Costa...")
            new_user = User(
                username='ana.costa',
                email='ana.costa@suaconsulta.com',
                full_name='Dra. Ana Costa',
                hashed_password=get_password_hash('senha123'),
                role=UserRole.DOCTOR.value,
                is_active=True
            )
            db.add(new_user)
            db.commit()
            db.refresh(new_user)
            
            new_medico = Medico(
                nome_completo='Dra. Ana Costa',
                crm='123456',
                crm_estado='SP',
                especialidade='Clínica Geral',
                email='ana.costa@suaconsulta.com',
                user_id=new_user.id
            )
            db.add(new_medico)
            db.commit()
            print("✅ Dra. Ana Costa criada com sucesso!")
        else:
            print("ℹ️ Dra. Ana Costa já existe.")
    except Exception as e:
        print(f"❌ Erro: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_ana()
