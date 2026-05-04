import sys
import os
import asyncio

# Adicionar o diretório backend ao path para importar app
sys.path.append(os.path.join(os.getcwd()))

from app.services.ingest_faq import ingest_all_doctors

EXTRA_PDFS_DIR = r"C:\Programacao\Alpha\LangChain\PDF's"

def run_ingestion():
    print(f"Iniciando ingestão de PDFs de: {EXTRA_PDFS_DIR}")
    results = ingest_all_doctors(extra_dirs=[EXTRA_PDFS_DIR])
    print(f"Ingestão concluída. Resultados: {results}")

if __name__ == "__main__":
    run_ingestion()
