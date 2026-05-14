import sqlite3
import os

db_path = r'omniconnect_test.db'
if not os.path.exists(db_path):
    print("DB not found")
else:
    conn = sqlite3.connect(db_path)
    patient = conn.execute("SELECT * FROM patients WHERE email='pedroasanti@yahoo.com.br'").fetchone()
    print(f"Patient: {patient}")
    conn.close()
