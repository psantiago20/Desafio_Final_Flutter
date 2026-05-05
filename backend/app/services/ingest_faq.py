"""
ingest_faq.py — Serviço de ingestão de documentos FAQ no ChromaDB

Lê arquivos .md e .txt da pasta faq/, faz chunking, gera embeddings
e indexa no ChromaDB para busca semântica posterior.
"""

import os
import logging
from typing import List, Dict, Optional, Any

import chromadb
from chromadb.config import Settings as ChromaSettings
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter

logger = logging.getLogger(__name__)

# Diretório base das FAQs (relativo ao workdir do container)
FAQ_BASE_DIR = os.environ.get("FAQ_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "faq"))
CHROMA_PERSIST_DIR = os.environ.get("CHROMA_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data"))

# Extensões suportadas
SUPPORTED_EXTENSIONS = {".md", ".txt", ".pdf"}

# Configuração de chunking
CHUNK_SIZE = 1000       # caracteres por chunk (aumentado para melhor contexto em PDFs)
CHUNK_OVERLAP = 100     # sobreposição entre chunks


def _get_chroma_client() -> chromadb.ClientAPI:
    """Retorna o cliente ChromaDB com persistência."""
    return chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)


def _get_collection_name(doctor_id: Optional[int]) -> str:
    """Gera o nome da collection no ChromaDB para um médico."""
    if doctor_id is None:
        return "faq_global"
    return f"faq_doctor_{doctor_id}"


def _read_file(filepath: str) -> str:
    """Lê o conteúdo de um arquivo (txt ou md)."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Erro ao ler arquivo {filepath}: {e}")
        return ""

def _load_pdf(filepath: str) -> List[str]:
    """Carrega conteúdo de um PDF e retorna lista de chunks."""
    try:
        loader = PyPDFLoader(filepath)
        docs = loader.load()
        # Retornar o conteúdo de cada página
        return [doc.page_content for doc in docs]
    except Exception as e:
        logger.error(f"Erro ao carregar PDF {filepath}: {e}")
        return []


def _chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    """
    Divide o texto em chunks utilizando o RecursiveCharacterTextSplitter do LangChain.
    """
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=overlap,
        separators=["\n\n", "\n", " ", ""]
    )
    return splitter.split_text(text)


def _scan_faq_directory(directory: str) -> List[Dict[str, Any]]:
    """
    Escaneia um diretório de FAQ e retorna lista de documentos.
    """
    documents = []
    
    if not os.path.exists(directory):
        logger.warning(f"Diretório de FAQ não encontrado: {directory}")
        return documents

    for filename in sorted(os.listdir(directory)):
        filepath = os.path.join(directory, filename)
        
        if not os.path.isfile(filepath):
            continue
            
        _, ext = os.path.splitext(filename)
        ext = ext.lower()
        if ext not in SUPPORTED_EXTENSIONS:
            continue

        if ext == ".pdf":
            pages = _load_pdf(filepath)
            if pages:
                documents.append({
                    "filepath": filepath,
                    "filename": filename,
                    "is_pdf": True,
                    "pages": pages
                })
                logger.info(f"  PDF carregado: {filename} ({len(pages)} páginas)")
        else:
            content = _read_file(filepath)
            if content.strip():
                documents.append({
                    "filepath": filepath,
                    "filename": filename,
                    "is_pdf": False,
                    "content": content
                })
                logger.info(f"  Arquivo texto carregado: {filename} ({len(content)} chars)")

    return documents


def ingest_doctor_faq(doctor_id: int, extra_dirs: List[str] = None) -> Dict[str, int]:
    """
    Indexa os documentos FAQ de um médico específico no ChromaDB.
    """
    client = _get_chroma_client()
    collection_name = _get_collection_name(doctor_id)

    # Deletar collection existente para re-indexar
    try:
        client.delete_collection(collection_name)
    except Exception:
        pass

    collection = client.get_or_create_collection(
        name=collection_name,
        metadata={"hnsw:space": "cosine"}
    )

    all_chunks = []
    all_metadatas = []
    all_ids = []
    chunk_counter = 0

    # Diretorios para escanear
    scan_dirs = [
        (os.path.join(FAQ_BASE_DIR, "_global"), "global"),
        (os.path.join(FAQ_BASE_DIR, f"doctor_{doctor_id}"), "doctor")
    ]
    
    if extra_dirs:
        for d in extra_dirs:
            if os.path.exists(d):
                scan_dirs.append((d, "extra"))

    for directory, scope in scan_dirs:
        docs = _scan_faq_directory(directory)
        for doc in docs:
            if doc.get("is_pdf"):
                for p_idx, page_content in enumerate(doc["pages"]):
                    chunks = _chunk_text(page_content)
                    for chunk in chunks:
                        all_chunks.append(chunk)
                        all_metadatas.append({
                            "source": doc["filename"],
                            "page": p_idx + 1,
                            "scope": scope,
                            "doctor_id": str(doctor_id),
                            "filepath": doc["filepath"]
                        })
                        all_ids.append(f"{scope}_{doc['filename']}_p{p_idx}_{chunk_counter}")
                        chunk_counter += 1
            else:
                chunks = _chunk_text(doc["content"])
                for chunk in chunks:
                    all_chunks.append(chunk)
                    all_metadatas.append({
                        "source": doc["filename"],
                        "scope": scope,
                        "doctor_id": str(doctor_id),
                        "filepath": doc["filepath"]
                    })
                    all_ids.append(f"{scope}_{doc['filename']}_{chunk_counter}")
                    chunk_counter += 1

    # Inserir no ChromaDB
    if all_chunks:
        batch_size = 100
        for i in range(0, len(all_chunks), batch_size):
            batch_end = min(i + batch_size, len(all_chunks))
            collection.add(
                documents=all_chunks[i:batch_end],
                metadatas=all_metadatas[i:batch_end],
                ids=all_ids[i:batch_end]
            )

    return {
        "doctor_id": doctor_id,
        "total_chunks": len(all_chunks)
    }


def ingest_all_doctors(extra_dirs: List[str] = None) -> List[Dict[str, int]]:
    """
    Indexa as FAQs de todos os médicos + diretórios extras.
    """
    results = []

    if not os.path.exists(FAQ_BASE_DIR):
        return results

    processed_doctors = False
    for entry in sorted(os.listdir(FAQ_BASE_DIR)):
        if entry.startswith("doctor_") and os.path.isdir(os.path.join(FAQ_BASE_DIR, entry)):
            try:
                doctor_id = int(entry.replace("doctor_", ""))
                stats = ingest_doctor_faq(doctor_id, extra_dirs)
                results.append(stats)
                processed_doctors = True
            except ValueError:
                continue

    if not processed_doctors:
        stats = ingest_doctor_faq(0, extra_dirs)
        results.append(stats)

    return results


def get_collection_stats() -> Dict:
    """Retorna estatísticas de todas as collections no ChromaDB."""
    client = _get_chroma_client()
    collections = client.list_collections()

    stats = {
        "total_collections": len(collections),
        "collections": []
    }

    for col in collections:
        collection = client.get_collection(col.name)
        stats["collections"].append({
            "name": col.name,
            "count": collection.count()
        })

    return stats

