import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from app.models import User, Patient, Appointment, Message, Service, Medico
from app.db.database import Base

load_dotenv()

DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://postgres:postgres@localhost:5432/omniconnect')

engine = create_engine(DATABASE_URL)
Base.metadata.create_all(bind=engine)
print('Tables created successfully')