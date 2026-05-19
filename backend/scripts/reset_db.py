from sqlalchemy import create_engine, text
from app.db.database import Base
from app.models import User, Patient, Appointment, Message, Service, Medico
from app.core.config import settings

DATABASE_URL = settings.DATABASE_URL

engine = create_engine(DATABASE_URL)

print('Limpando banco de dados (Drop all tables)...')
# Drop tables in correct order or use CASCADE
with engine.connect() as conn:
    conn.execute(text("DROP TABLE IF EXISTS messages CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS exams CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS services CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS appointments CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS medicos CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS patients CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS doctor_profiles CASCADE"))
    conn.execute(text("DROP TABLE IF EXISTS users CASCADE"))
    conn.commit()

print('Criando tabelas novamente...')
Base.metadata.create_all(bind=engine)
print('Tabelas criadas com sucesso!')
