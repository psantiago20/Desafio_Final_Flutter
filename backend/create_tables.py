from sqlalchemy import create_engine
from app.models import User, Patient, Appointment, Message, Service
from app.db.database import Base

DATABASE_URL = 'postgresql://postgres:P2706303-2p@localhost:5432/omniconnect'

engine = create_engine(DATABASE_URL)
Base.metadata.create_all(bind=engine)
print('Tables created successfully')