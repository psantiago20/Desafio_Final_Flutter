import asyncio
import time
import logging
from app.services.rag_service import rag_service

from app.database import get_db

logging.basicConfig(level=logging.INFO)

async def test_latency():
    db = next(get_db())
    start = time.time()
    try:
        res = await rag_service.get_rag_response('quais medicos atendem', '5511999999999', db)
        end = time.time()
        print(f'\n--- Resultado ---')
        print(f'Tempo total: {end-start:.2f}s')
        print(f'Resposta: {res}')
    except Exception as e:
        print(f'Erro: {e}')
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_latency())
