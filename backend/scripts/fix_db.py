import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.environ.get("DATABASE_URL")

engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    try:
        conn.execute(text("ALTER TABLE appointments ADD COLUMN medico_id INTEGER REFERENCES medicos(id);"))
        conn.commit()
        print("Column medico_id added successfully.")
    except Exception as e:
        print(f"Error adding column: {e}")
