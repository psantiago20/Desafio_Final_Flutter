from sqlalchemy import create_engine, text
from app.core.config import settings

db_url = settings.DATABASE_URL
if db_url.startswith("postgresql://"):
    # Substitui o nome do banco no final por 'postgres' para conectar e criar o banco do projeto
    parts = db_url.rsplit('/', 1)
    DATABASE_URL = f"{parts[0]}/postgres"
else:
    DATABASE_URL = db_url

engine = create_engine(
    DATABASE_URL,
    isolation_level='AUTOCOMMIT'
)
with engine.connect() as conn:
    try:
        conn.execute(text('CREATE DATABASE omniconnect'))
        print('Database created')
    except Exception as e:
        if 'already exists' in str(e) or 'duplicate database' in str(e):
            print('Database omniconnect already exists. Skipping database creation.')
        else:
            print(f'Error creating database: {e}')
            raise e

engine.dispose()