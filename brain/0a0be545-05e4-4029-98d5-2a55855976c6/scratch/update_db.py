import sqlite3
import os

db_path = r'c:\Programacao\Alpha\Desafio_final_Flutter\backend\omniconnect_test.db'

if os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    columns_to_add = [
        ('blood_type', 'VARCHAR(5)'),
        ('allergies', 'TEXT'),
        ('chronic_conditions', 'TEXT'),
        ('medications', 'TEXT')
    ]
    
    for col_name, col_type in columns_to_add:
        try:
            cursor.execute(f"ALTER TABLE patients ADD COLUMN {col_name} {col_type}")
            print(f"Added column {col_name} to patients table.")
        except sqlite3.OperationalError as e:
            if 'duplicate column name' in str(e).lower():
                print(f"Column {col_name} already exists.")
            else:
                print(f"Error adding {col_name}: {e}")
    
    conn.commit()
    conn.close()
else:
    print(f"Database not found at {db_path}")
