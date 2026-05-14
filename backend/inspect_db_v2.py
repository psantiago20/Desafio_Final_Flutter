import sqlite3
import os

for db_path in ["backend/app.db", "backend/test.db", "app.db", "test.db"]:
    if os.path.exists(db_path):
        print(f"Checking {db_path}...")
        try:
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = cursor.fetchall()
            print(f"Tables: {tables}")
            if ('medicos',) in tables:
                cursor.execute("SELECT id, nome_completo FROM medicos;")
                rows = cursor.fetchall()
                for row in rows:
                    print(row)
            conn.close()
        except Exception as e:
            print(f"Error: {e}")
