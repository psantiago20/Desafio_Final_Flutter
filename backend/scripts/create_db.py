from sqlalchemy import create_engine, text
from sqlalchemy.pool import StaticPool

engine = create_engine(
    'postgresql://postgres:P2706303-2p@localhost:5432/postgres',
    isolation_level='AUTOCOMMIT'
)
with engine.connect() as conn:
    conn.execute(text('CREATE DATABASE omniconnect'))
    print('Database created')

engine.dispose()