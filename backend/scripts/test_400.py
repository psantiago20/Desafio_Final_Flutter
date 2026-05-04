import asyncio
from app.services.rag_service import rag_service

from app.db.database import SessionLocal

async def test():
    print('Testing...')
    db = SessionLocal()
    rag_service.clear_conversation('5511988888888_test')
    res = await rag_service.get_rag_response('5511988888888_test', 'médicos', db)
    print('Medicos OK')
    res2 = await rag_service.get_rag_response('5511988888888_test', 'datas', db)
    print('Datas OK')

asyncio.run(test())
