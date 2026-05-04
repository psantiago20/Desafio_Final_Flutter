from mcp.server.fastmcp import FastMCP
import logging
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.services.agent_tools import buscar_faq, buscar_medico, buscar_horarios, buscar_agendamentos

# Configuração de logs
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("OmniConnect-MCP")

# Inicializa o FastMCP
mcp = FastMCP("OmniConnect")

@mcp.tool()
def search_faq(pergunta: str, medico_id: int = None) -> str:
    """
    Busca na base de conhecimento (FAQ) por informações gerais como:
    preparo para exames, convênios aceitos, política de cancelamento, etc.
    """
    logger.info(f"MCP Tool: search_faq({pergunta})")
    return buscar_faq(pergunta=pergunta, medico_id=medico_id)

@mcp.tool()
def get_doctor_info(nome: str = None, crm: str = None, especialidade: str = None) -> str:
    """
    Busca dados de um médico no banco de dados por nome, CRM ou especialidade.
    """
    logger.info(f"MCP Tool: get_doctor_info(nome={nome})")
    db = SessionLocal()
    try:
        return buscar_medico(db=db, nome=nome, crm=crm, especialidade=especialidade)
    finally:
        db.close()

@mcp.tool()
def get_doctor_schedule(medico_id: int = None, nome_medico: str = None) -> str:
    """
    Busca os horários de atendimento e disponibilidade de um médico.
    """
    logger.info(f"MCP Tool: get_doctor_schedule(id={medico_id})")
    db = SessionLocal()
    try:
        return buscar_horarios(db=db, medico_id=medico_id, nome_medico=nome_medico)
    finally:
        db.close()

@mcp.tool()
def get_patient_appointments(cpf: str) -> str:
    """
    Busca os agendamentos (consultas) de um paciente pelo CPF.
    """
    logger.info(f"MCP Tool: get_patient_appointments(cpf={cpf})")
    db = SessionLocal()
    try:
        return buscar_agendamentos(db=db, cpf=cpf)
    finally:
        db.close()

if __name__ == "__main__":
    # Quando executado diretamente, o FastMCP pode rodar via stdio (padrão MCP)
    mcp.run()
