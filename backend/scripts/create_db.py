import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

# Use a URL baseada no postgres para criar o banco omniconnect
DATABASE_URL = os.getenv('DATABASE_URL_POSTGRES', 'postgresql://postgres:postgres@localhost:5432/postgres')

engine = create_engine(
    DATABASE_URL,
    isolation_level='AUTOCOMMIT'
)
with engine.connect() as conn:
    conn.execute(text('CREATE DATABASE omniconnect'))
    print('Database created')

engine.dispose()