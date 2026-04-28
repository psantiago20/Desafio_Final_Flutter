from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, Numeric
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class Medico(Base):
    """
    Tabela MEDICO — Profissional contratante da plataforma.
    
    Cada médico que fecha contrato com o OmniConnect recebe:
    - Um registro nesta tabela
    - Um número WhatsApp Business próprio (whatsapp_phone_number_id)
    - Uma pasta de FAQ em backend/faq/doctor_{id}/
    
    Esta tabela é a fonte de verdade para o Agente de IA buscar dados
    do médico via Tool Calling.
    """
    __tablename__ = "medicos"

    id = Column(Integer, primary_key=True, index=True)

    # Dados pessoais / profissionais
    nome_completo = Column(String(200), nullable=False)
    crm = Column(String(20), unique=True, nullable=False, index=True)
    crm_estado = Column(String(2), nullable=False)  # UF: SP, RJ, MG...
    especialidade = Column(String(200), nullable=False)
    email = Column(String(255), unique=True, index=True)
    telefone = Column(String(20))

    # Localização
    cidade = Column(String(100))                            # Cidade do consultório
    endereco = Column(String(300))                          # Endereço completo

    # WhatsApp Business (cada médico tem seu número)
    whatsapp = Column(String(20))                          # Número exibido ao paciente
    whatsapp_phone_number_id = Column(String(50), unique=True, index=True)  # ID da Meta
    whatsapp_access_token = Column(String(500))            # Token WABA do médico

    # Perfil público
    bio_resumida = Column(Text)                             # Bio curta para o paciente
    foto_url = Column(String(500))                          # URL da foto do médico

    # Configurações de consulta
    duracao_consulta_min = Column(Integer, default=30)
    valor_consulta = Column(Numeric(10, 2))                 # Decimal para valores monetários

    # Convênios
    aceita_convenio = Column(Boolean, default=False)
    convenios = Column(Text)                                # JSON array: ["Unimed", "Bradesco"]

    # FK opcional para User (login no app do médico)
    user_id = Column(Integer, nullable=True)                # Sem FK formal para não acoplar

    # Controle
    ativo = Column(Boolean, default=True)
    criado_em = Column(DateTime, default=datetime.utcnow)

    # Relationships
    agendamentos = relationship(
        "Appointment",
        back_populates="medico",
        foreign_keys="Appointment.medico_id"
    )
