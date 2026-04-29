"""
ingest_faq.py — Serviço de ingestão de documentos FAQ no ChromaDB

Lê arquivos .md e .txt da pasta faq/, faz chunking, gera embeddings
e indexa no ChromaDB para busca semântica posterior.
"""

import os
import logging
from typing import List, Dict, Optional

import chromadb
from chromadb.config import Settings as ChromaSettings

logger = logging.getLogger(__name__)

# Diretório base das FAQs (relativo ao workdir do container)
FAQ_BASE_DIR = os.environ.get("FAQ_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "faq"))
CHROMA_PERSIST_DIR = os.environ.get("CHROMA_DIR", os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data"))

# Extensões suportadas
SUPPORTED_EXTENSIONS = {".md", ".txt"}

# Configuração de chunking
CHUNK_SIZE = 500       # caracteres por chunk
CHUNK_OVERLAP = 50     # sobreposição entre chunks


def _get_chroma_client() -> chromadb.ClientAPI:
    """Retorna o cliente ChromaDB com persistência."""
    return chromadb.PersistentClient(path=CHROMA_PERSIST_DIR)


def _get_collection_name(doctor_id: Optional[int]) -> str:
    """Gera o nome da collection no ChromaDB para um médico."""
    if doctor_id is None:
        return "faq_global"
    return f"faq_doctor_{doctor_id}"


def _read_file(filepath: str) -> str:
    """Lê o conteúdo de um arquivo."""
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    except Exception as e:
        logger.error(f"Erro ao ler arquivo {filepath}: {e}")
        return ""


def _chunk_text(text: str, chunk_size: int = CHUNK_SIZE, overlap: int = CHUNK_OVERLAP) -> List[str]:
    """
    Divide o texto em chunks com sobreposição.
    Tenta quebrar em limites de parágrafo/linha quando possível.
    """
    if not text or len(text) <= chunk_size:
        return [text] if text.strip() else []

    chunks = []
    start = 0
    text_len = len(text)

    while start < text_len:
        end = min(start + chunk_size, text_len)

        # Tentar quebrar no final de um parágrafo ou linha
        if end < text_len:
            # Procurar quebra de parágrafo
            para_break = text.rfind("\n\n", start, end)
            if para_break > start + chunk_size // 2:
                end = para_break + 2
            else:
                # Procurar quebra de linha
                line_break = text.rfind("\n", start, end)
                if line_break > start + chunk_size // 2:
                    end = line_break + 1

        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)

        start = end - overlap if end < text_len else text_len

    return chunks


def _scan_faq_directory(directory: str) -> List[Dict[str, str]]:
    """
    Escaneia um diretório de FAQ e retorna lista de documentos.
    
    Returns:
        Lista de dicts com 'filepath', 'filename', 'content'
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
        if ext.lower() not in SUPPORTED_EXTENSIONS:
            continue

        content = _read_file(filepath)
        if content.strip():
            documents.append({
                "filepath": filepath,
                "filename": filename,
                "content": content
            })
            logger.info(f"  Arquivo carregado: {filename} ({len(content)} chars)")

    return documents


def ingest_doctor_faq(doctor_id: int) -> Dict[str, int]:
    """
    Indexa os documentos FAQ de um médico específico no ChromaDB.
    Inclui tanto os documentos globais (_global/) quanto os específicos (doctor_{id}/).
    
    Args:
        doctor_id: ID do médico (corresponde ao DoctorProfile.id)
        
    Returns:
        Dict com estatísticas da ingestão
    """
    client = _get_chroma_client()
    collection_name = _get_collection_name(doctor_id)

    # Deletar collection existente para re-indexar
    try:
        client.delete_collection(collection_name)
        logger.info(f"Collection '{collection_name}' deletada para re-indexação")
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

    # 1. Carregar documentos globais
    global_dir = os.path.join(FAQ_BASE_DIR, "_global")
    global_docs = _scan_faq_directory(global_dir)
    logger.info(f"Carregados {len(global_docs)} documentos globais")

    for doc in global_docs:
        chunks = _chunk_text(doc["content"])
        for chunk in chunks:
            all_chunks.append(chunk)
            all_metadatas.append({
                "source": doc["filename"],
                "scope": "global",
                "doctor_id": str(doctor_id),
                "filepath": doc["filepath"]
            })
            all_ids.append(f"global_{doc['filename']}_{chunk_counter}")
            chunk_counter += 1

    # 2. Carregar documentos específicos do médico
    doctor_dir = os.path.join(FAQ_BASE_DIR, f"doctor_{doctor_id}")
    doctor_docs = _scan_faq_directory(doctor_dir)
    logger.info(f"Carregados {len(doctor_docs)} documentos do médico {doctor_id}")

    for doc in doctor_docs:
        chunks = _chunk_text(doc["content"])
        for chunk in chunks:
            all_chunks.append(chunk)
            all_metadatas.append({
                "source": doc["filename"],
                "scope": "doctor",
                "doctor_id": str(doctor_id),
                "filepath": doc["filepath"]
            })
            all_ids.append(f"doctor_{doctor_id}_{doc['filename']}_{chunk_counter}")
            chunk_counter += 1

    # 3. Inserir no ChromaDB
    if all_chunks:
        # ChromaDB tem limite de batch, inserir em lotes de 100
        batch_size = 100
        for i in range(0, len(all_chunks), batch_size):
            batch_end = min(i + batch_size, len(all_chunks))
            collection.add(
                documents=all_chunks[i:batch_end],
                metadatas=all_metadatas[i:batch_end],
                ids=all_ids[i:batch_end]
            )
        logger.info(f"Indexados {len(all_chunks)} chunks para doctor_id={doctor_id}")

    stats = {
        "doctor_id": doctor_id,
        "collection_name": collection_name,
        "global_documents": len(global_docs),
        "doctor_documents": len(doctor_docs),
        "total_chunks": len(all_chunks)
    }
    logger.info(f"Ingestão concluída: {stats}")
    return stats


def ingest_all_doctors() -> List[Dict[str, int]]:
    """
    Indexa as FAQs de todos os médicos que possuem pasta em faq/.
    
    Returns:
        Lista com estatísticas de cada médico processado
    """
    results = []

    if not os.path.exists(FAQ_BASE_DIR):
        logger.error(f"Diretório base de FAQ não encontrado: {FAQ_BASE_DIR}")
        return results

    for entry in sorted(os.listdir(FAQ_BASE_DIR)):
        if entry.startswith("doctor_") and os.path.isdir(os.path.join(FAQ_BASE_DIR, entry)):
            try:
                doctor_id = int(entry.replace("doctor_", ""))
                stats = ingest_doctor_faq(doctor_id)
                results.append(stats)
            except ValueError:
                logger.warning(f"Nome de pasta inválido (esperado doctor_N): {entry}")
                continue

    # Se não achou nenhum doctor_, pelo menos indexar o global como doctor_id=0
    if not results:
        logger.info("Nenhuma pasta doctor_N encontrada. Indexando apenas FAQ global como doctor_id=0")
        stats = ingest_doctor_faq(0)
        results.append(stats)

    return results


def get_collection_stats() -> Dict:
    """Retorna estatísticas de todas as collections no ChromaDB."""
    client = _get_chroma_client()
    collections = client.list_collections()

    stats = {
        "total_collections": len(collections),
        "chroma_dir": CHROMA_PERSIST_DIR,
        "faq_dir": FAQ_BASE_DIR,
        "collections": []
    }

    for col in collections:
        collection = client.get_collection(col.name)
        stats["collections"].append({
            "name": col.name,
            "count": collection.count()
        })

    return stats
