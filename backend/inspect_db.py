import sqlite3
import os

db_path = "backend/omniconnect_test.db"
if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT id, nome_completo, especialidade FROM medicos;")
    rows = cursor.fetchall()
    for row in rows:
        print(row)
    conn.close()
else:
    print(f"File {db_path} not found.")
