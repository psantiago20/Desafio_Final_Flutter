"""
rag.py — Endpoints de administração do RAG

Endpoints para:
- Ingestão/re-indexação de FAQs
- Teste de busca semântica
- Teste do pipeline RAG completo
- Estatísticas do vector store
"""

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import logging
import os
import uuid
import shutil
import json
import base64
from langchain_nvidia_ai_endpoints import ChatNVIDIA
from langchain_core.messages import HumanMessage
from app.core.config import settings

from app.db.database import get_db
from app.models.patient import Patient
from app.models.appointment import Appointment
from app.models.exam import Exam
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
    wa_to: Optional[str] = None
    top_k: int = 5
    wa_from: Optional[str] = None  # Número WhatsApp (para tracking de estado)
    source: str = "app"  # Origem (app ou whatsapp)


class RAGQueryResponse(BaseModel):
    query: str
    wa_to: Optional[str]
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
        # Buscar chunks para retornar a contagem (usando id 1 por enquanto para faq, ou ignorar doctor_id)
        chunks = rag_service.search_only(
            query=request.query,
            doctor_id=None,
            top_k=request.top_k
        )

        # Pipeline completo (com gerenciamento de estado se wa_from fornecido)
        response = await rag_service.get_rag_response(
            query=request.query,
            wa_to=request.wa_to,
            db=db,
            wa_from=request.wa_from,
            source=request.source
        )

        return RAGQueryResponse(
            query=request.query,
            wa_to=request.wa_to,
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

@router.post("/upload-exam")
async def upload_exam(
    wa_from: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """
    Recebe um exame médico em formato de imagem, passa pela IA Vision,
    e anexa o resumo à próxima consulta do paciente.
    """
    try:
        # 1. Preparar diretório
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
        exams_dir = os.path.join(base_dir, "static", "exams")
        os.makedirs(exams_dir, exist_ok=True)
        
        # 2. Salvar o arquivo físico
        ext = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{ext}"
        file_path = os.path.join(exams_dir, unique_filename)
        
        content = await file.read()
        with open(file_path, "wb") as buffer:
            buffer.write(content)
            
        # 3. IA Vision: Analisar a imagem de verdade usando LLaMA 3.2 Vision
        import base64
        from langchain_nvidia_ai_endpoints import ChatNVIDIA
        from langchain_core.messages import HumanMessage

        print(f"[VISION] Analisando exame: {file.filename}")
        encoded_image = base64.b64encode(content).decode("utf-8")
        
        vision_model = ChatNVIDIA(model="meta/llama-3.2-11b-vision-instruct", nvidia_api_key=settings.NVIDIA_API_KEY)
        
        prompt = (
            "Analise este exame médico e responda APENAS em formato JSON com os seguintes campos:\n"
            "{\n"
            "  \"title\": \"Nome curto do exame (ex: Hemograma Completo)\",\n"
            "  \"summary\": \"Resumo de 2 frases sobre os resultados\"\n"
            "}\n"
            "Não use blocos de código markdown, apenas o JSON puro."
        )
        
        message = HumanMessage(
            content=[
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{encoded_image}"}},
            ]
        )
        
        try:
            response = vision_model.invoke([message])
            logger.info(f"[VISION] Resposta da IA: {response.content}")
            clean_content = response.content.replace("```json", "").replace("```", "").strip()
            ai_data = json.loads(clean_content)
            exam_title = ai_data.get("title", "Exame Médico")
            exam_summary = ai_data.get("summary", "Análise realizada via IA Vision.")
        except Exception as vision_err:
            logger.error(f"[VISION ERROR] Falha na análise: {str(vision_err)}")
            exam_title = f"Exame: {file.filename}"
            exam_summary = "O exame foi recebido, mas a análise automática falhou."

        public_url = f"/static/exams/{unique_filename}"
        
        # 4. Procurar o paciente
        patient = db.query(Patient).filter(
            (Patient.phone == wa_from) | (Patient.whatsapp == wa_from) | (Patient.email == wa_from)
        ).first()
        
        if not patient:
            return {"status": "error", "message": "Paciente não encontrado."}

        # 5. Salvar registro no banco
        new_exam = Exam(
            patient_id=patient.id,
            title=exam_title,
            exam_url=public_url,
            summary=exam_summary
        )
        db.add(new_exam)

        # Opcional: Tenta vincular à consulta mais recente se existir
        next_app = db.query(Appointment).filter(
            Appointment.patient_id == patient.id
        ).order_by(Appointment.appointment_date.desc()).first()
            
        if next_app:
            next_app.exam_url = public_url
            next_app.exam_summary = exam_summary
            
        db.commit()
        return {
            "status": "success", 
            "title": exam_title,
            "summary": exam_summary,
            "url": public_url
        }
            
    except Exception as e:
        logger.error(f"Erro ao processar exame: {e}")
        raise HTTPException(status_code=500, detail=str(e))
