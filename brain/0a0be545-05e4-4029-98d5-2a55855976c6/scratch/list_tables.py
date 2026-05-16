import sqlite3

for db_file in ['omniconnect_test.db', 'app.db']:
    print(f"--- Tables in {db_file} ---")
    try:
        conn = sqlite3.connect(db_file)
        tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table';").fetchall()
        for table in tables:
            print(table[0])
        conn.close()
    except Exception as e:
        print(f"Error: {e}")
