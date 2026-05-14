import sys
import os
sys.path.append('.')
from app.db.database import SessionLocal
from app.models.user import User
from app.models.medico import Medico

db = SessionLocal()
try:
    medico = db.query(Medico).filter(Medico.nome_completo.ilike('%Thorne Blackwood%')).first()
    if medico:
        print(f'Medico encontrado: {medico.nome_completo}, email: {medico.email}, user_id: {medico.user_id}')
        if medico.user_id:
            user = db.query(User).filter(User.id == medico.user_id).first()
            if user:
                print(f'User username: {user.username}, email: {user.email}')
            else:
                print('Sem User correspondente no BD')
        else:
            print('Nenhum user_id vinculado a esse medico.')
    else:
        print('Medico nao encontrado no DB.')
except Exception as e:
    print(e)
finally:
    db.close()
