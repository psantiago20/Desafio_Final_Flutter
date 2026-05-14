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
import mimetypes
from pypdf import PdfReader
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
    Agora persiste as mensagens no banco de dados para histórico permanente.
    """
    try:
        from app.models.message import Message, MessageSource
        from app.models.patient import Patient
        from app.utils.phone_utils import find_patient_by_messaging_phone

        # 1. Identificar o paciente
        patient = None
        if request.wa_from:
            patient = find_patient_by_messaging_phone(db, request.wa_from)

        # 2. Salvar mensagem do usuário no banco (se paciente identificado)
        if patient:
            user_msg = Message(
                patient_id=patient.id,
                content=request.query,
                source=request.source,
                wa_from=request.wa_from
            )
            db.add(user_msg)
            db.commit()

        # 3. Buscar chunks para retornar a contagem
        chunks = rag_service.search_only(
            query=request.query,
            doctor_id=None,
            top_k=request.top_k
        )

        # 4. Pipeline completo
        response = await rag_service.get_rag_response(
            query=request.query,
            wa_to=request.wa_to,
            db=db,
            wa_from=request.wa_from,
            source=request.source
        )

        # 5. Salvar resposta da IA no banco (se paciente identificado)
        if patient:
            ai_msg = Message(
                patient_id=patient.id,
                content=response,
                source=MessageSource.SYSTEM.value,
                wa_from="isis_ia"
            )
            db.add(ai_msg)
            db.commit()

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
    Recebe um exame médico em formato de imagem ou PDF, passa pela IA,
    e anexa o resumo à próxima consulta do paciente.
    """
    try:
        # 1. Preparar diretório e identificar tipo de arquivo
        import mimetypes, uuid, os, json
        from pypdf import PdfReader
        from langchain_nvidia_ai_endpoints import ChatNVIDIA
        from langchain_core.messages import HumanMessage
        
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
        exams_dir = os.path.join(base_dir, "static", "exams")
        os.makedirs(exams_dir, exist_ok=True)
        
        content = await file.read()
        mime_type, _ = mimetypes.guess_type(file.filename)
        is_pdf = mime_type == "application/pdf" or file.filename.lower().endswith(".pdf")
        
        # 2. Salvar o arquivo físico
        ext = os.path.splitext(file.filename)[1]
        unique_filename = f"{uuid.uuid4()}{ext}"
        file_path = os.path.join(exams_dir, unique_filename)
        
        with open(file_path, "wb") as buffer:
            buffer.write(content)
            
        # 3. Análise IA (Vision para Imagem, Text para PDF)
        exam_title = f"Exame: {file.filename}"
        exam_summary = "Análise automática indisponível."

        try:
            if is_pdf:
                # Lógica para PDF: Extração de Texto
                from io import BytesIO
                reader = PdfReader(BytesIO(content))
                text_content = ""
                for page in reader.pages:
                    text_content += page.extract_text() + "\n"
                
                if not text_content.strip():
                    exam_summary = "O PDF parece ser uma imagem digitalizada. Por favor, envie uma foto nítida do exame para análise."
                else:
                    llm = ChatNVIDIA(model="meta/llama-3.1-70b-instruct", nvidia_api_key=settings.NVIDIA_API_KEY)
                    prompt = (
                        "Analise o texto deste exame médico e retorne APENAS um JSON.\n"
                        "REGRAS PARA O 'summary':\n"
                        "1. Se estiver TUDO NORMAL: o summary deve ser EXATAMENTE 'Os resultados estão dentro dos valores de referência.' e nada mais.\n"
                        "2. Se houver ALTERAÇÃO: cite apenas o dado alterado de forma direta (ex: 'Hemoglobina baixa: 10 g/dL').\n"
                        f"TEXTO: {text_content[:4000]}\n\n"
                        "FORMATO JSON:\n"
                        "{\n"
                        "  \"title\": \"Nome do exame\",\n"
                        "  \"summary\": \"\"\n"
                        "}"
                    )
                    response = llm.invoke(prompt)
                    clean_content = response.content.replace("```json", "").replace("```", "").strip()
                    ai_data = json.loads(clean_content)
                    exam_title = ai_data.get("title", exam_title)
                    exam_summary = ai_data.get("summary", exam_summary)
            else:
                # Lógica para Imagem: Vision
                import base64
                encoded_image = base64.b64encode(content).decode("utf-8")
                vision_model = ChatNVIDIA(model="meta/llama-3.2-11b-vision-instruct", nvidia_api_key=settings.NVIDIA_API_KEY)
                
                prompt = (
                    "Analise este exame médico e responda APENAS em formato JSON.\n"
                    "REGRAS PARA O 'summary':\n"
                    "1. Se estiver TUDO NORMAL: o summary deve ser EXATAMENTE 'Os resultados estão dentro dos valores de referência.' e nada mais.\n"
                    "2. Se houver ALTERAÇÃO: cite apenas o dado alterado de forma direta (ex: 'Glicemia elevada: 115 mg/dL').\n"
                    "FORMATO JSON:\n"
                    "{\n"
                    "  \"title\": \"Nome do exame\",\n"
                    "  \"summary\": \"\"\n"
                    "}"
                )
                
                message = HumanMessage(
                    content=[
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": f"data:{mime_type or 'image/png'};base64,{encoded_image}"}},
                    ]
                )
                response = vision_model.invoke([message])
                clean_content = response.content.replace("```json", "").replace("```", "").strip()
                ai_data = json.loads(clean_content)
                exam_title = ai_data.get("title", exam_title)
                exam_summary = ai_data.get("summary", exam_summary)

        except Exception as ai_err:
            logger.error(f"[AI ERROR] Falha na análise: {str(ai_err)}")
            exam_summary = "Análise automática indisponível."

        public_url = f"/static/exams/{unique_filename}"
        
        # 4. Procurar o paciente
        from app.utils.phone_utils import find_patient_for_contact
        patient = find_patient_for_contact(db, wa_from)
        
        if not patient:
            return {"status": "error", "message": "Paciente não encontrado."}

        # 5. Salvar registro no banco e no chat
        from app.models.exam import Exam
        new_exam = Exam(
            patient_id=patient.id,
            title=exam_title,
            exam_url=public_url,
            summary=exam_summary
        )
        db.add(new_exam)

        from app.models.message import Message, MessageSource
        db.add(Message(
            patient_id=patient.id,
            content=f"Enviando exame: {file.filename}",
            source=MessageSource.APP.value,
            wa_from=wa_from
        ))
        
        db.add(Message(
            patient_id=patient.id,
            content="Recebi seu exame! 💌",
            source=MessageSource.SYSTEM.value,
            wa_from="isis_ia"
        ))

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
