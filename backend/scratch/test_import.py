import sys
import os
import time

print("Iniciando teste de importação...")
sys.path.append(os.getcwd())

start = time.time()
try:
    print("Importando app.services.rag_service...")
    from app.services.rag_service import rag_service
    print(f"Importação concluída em {time.time() - start:.2f}s")
except Exception as e:
    print(f"Erro na importação: {e}")

print("Fim do teste.")
