from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class MedicoBase(BaseModel):
    nome_completo: str
    crm: str
    crm_estado: str
    especialidade: str
    email: Optional[str] = None
    telefone: Optional[str] = None
    cidade: Optional[str] = None
    endereco: Optional[str] = None
    whatsapp: Optional[str] = None
    bio_resumida: Optional[str] = None
    foto_url: Optional[str] = None
    valor_consulta: Optional[float] = None
    aceita_convenio: bool = False
    convenios: Optional[str] = None

class MedicoResponse(MedicoBase):
    id: int
    user_id: Optional[int] = None
    ativo: bool
    criado_em: datetime

    class Config:
        from_attributes = True
