"""
rag.py — Endpoints de administração do RAG

Endpoints para:
- Ingestão/re-indexação de FAQs
- Teste de busca semântica
- Teste do pipeline RAG completo
- Estatísticas do vector store
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging

from app.db.database import get_db
from app.services.ingest_faq import ingest_doctor_faq, ingest_all_doctors, get_collection_stats
from app.services.rag_service import rag_service

router = APIRouter()
logger = logging.getLogger(__name__)


# ------------------------------------------------------------------ #
#  Schemas
# ------------------------------------------------------------------ #

class IngestResponse(BaseModel):
    status: str
    message: str
    stats: Any


class SearchRequest(BaseModel):
    query: str
    doctor_id: Optional[int] = None
    top_k: int = 5


class SearchResult(BaseModel):
    content: str
    source: str
    scope: str
    distance: Optional[float] = None


class SearchResponse(BaseModel):
    query: str
    doctor_id: Optional[int]
    results: List[SearchResult]
    total: int


class RAGQueryRequest(BaseModel):
    query: str
    doctor_id: Optional[int] = None
    top_k: int = 5


class RAGQueryResponse(BaseModel):
    query: str
    doctor_id: Optional[int]
    response: str
    faq_chunks_used: int


# ------------------------------------------------------------------ #
#  Endpoints de Ingestão
# ------------------------------------------------------------------ #

@router.post("/ingest/{doctor_id}", response_model=IngestResponse)
def ingest_faq(doctor_id: int):
    """
    Re-indexa os documentos FAQ de um médico específico.
    Lê os arquivos de faq/_global/ e faq/doctor_{id}/ e indexa no ChromaDB.
    """
    try:
        logger.info(f"Iniciando ingestão da FAQ para doctor_id={doctor_id}")
        stats = ingest_doctor_faq(doctor_id)
        return IngestResponse(
            status="success",
            message=f"FAQ do médico {doctor_id} indexada com sucesso",
            stats=stats
        )
    except Exception as e:
        logger.error(f"Erro na ingestão: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/ingest/all", response_model=IngestResponse)
def ingest_all():
    """
    Re-indexa os documentos FAQ de TODOS os médicos.
    Escaneia todas as pastas doctor_N/ em faq/.
    """
    try:
        logger.info("Iniciando ingestão de todas as FAQs")
        results = ingest_all_doctors()
        return IngestResponse(
            status="success",
            message=f"FAQ indexada para {len(results)} médicos",
            stats=results
        )
    except Exception as e:
        logger.error(f"Erro na ingestão geral: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ------------------------------------------------------------------ #
#  Endpoints de Busca e Teste
# ------------------------------------------------------------------ #

@router.post("/search", response_model=SearchResponse)
def search_faq(request: SearchRequest):
    """
    Busca semântica na FAQ (sem chamar a LLM).
    Útil para testar a qualidade da busca do vector store.
    """
    try:
        results = rag_service.search_only(
            query=request.query,
            doctor_id=request.doctor_id,
            top_k=request.top_k
        )
        return SearchResponse(
            query=request.query,
            doctor_id=request.doctor_id,
            results=[SearchResult(**r) for r in results],
            total=len(results)
        )
    except Exception as e:
        logger.error(f"Erro na busca: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/query", response_model=RAGQueryResponse)
async def query_rag(
    request: RAGQueryRequest,
    db: Session = Depends(get_db)
):
    """
    Pipeline RAG completo: busca FAQ + dados do médico → LLM → resposta.
    Endpoint para testar o RAG diretamente.
    """
    try:
        # Buscar chunks para retornar a contagem
        chunks = rag_service.search_only(
            query=request.query,
            doctor_id=request.doctor_id,
            top_k=request.top_k
        )

        # Pipeline completo
        response = await rag_service.get_rag_response(
            query=request.query,
            doctor_id=request.doctor_id,
            db=db,
            top_k=request.top_k
        )

        return RAGQueryResponse(
            query=request.query,
            doctor_id=request.doctor_id,
            response=response,
            faq_chunks_used=len(chunks)
        )
    except Exception as e:
        logger.error(f"Erro no RAG query: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ------------------------------------------------------------------ #
#  Estatísticas
# ------------------------------------------------------------------ #

@router.get("/stats")
def rag_stats():
    """Retorna estatísticas do vector store (collections, contagem de documentos)."""
    try:
        stats = get_collection_stats()
        return {"status": "success", "data": stats}
    except Exception as e:
        logger.error(f"Erro ao obter stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))
