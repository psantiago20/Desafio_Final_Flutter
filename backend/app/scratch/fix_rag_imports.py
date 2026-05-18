import os

file_path = r'c:\Programacao\Alpha\Desafio_final_Flutter\backend\app\api\endpoints\rag.py'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_imports = [
    "from app.db.database import get_db\n",
    "from app.api.deps import get_current_active_user\n",
    "from app.models.user import User\n",
    "from app.models.message import Message, MessageSource\n",
    "from app.models.patient import Patient\n",
    "from app.models.appointment import Appointment\n",
    "from app.models.exam import Exam\n",
    "from app.api.endpoints.whatsapp import find_patient_by_messaging_phone\n",
    "from app.services.ingest_faq import ingest_doctor_faq, ingest_all_doctors, get_collection_stats\n",
    "from app.services.rag_service import rag_service\n",
    "from app.services.transcription_service import transcription_service\n"
]

# Encontrar onde começam os imports (depois do docstring)
start_idx = 0
for i, line in enumerate(lines):
    if line.startswith("from app.db.database"):
        start_idx = i
        break

if start_idx > 0:
    # Encontrar onde terminam os imports antigos
    end_idx = start_idx
    for i in range(start_idx, len(lines)):
        if lines[i].strip() == "" or lines[i].startswith("router ="):
            end_idx = i
            break
    
    # Substituir o bloco de imports
    final_lines = lines[:start_idx] + new_imports + lines[end_idx:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(final_lines)
    print("Sucesso ao atualizar imports")
else:
    print("Não encontrei o local dos imports")
