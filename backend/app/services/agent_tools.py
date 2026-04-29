"""
agent_tools.py — Funções (tools) que o Agente de IA pode chamar

Estas funções são chamadas dinamicamente pela LLM via Tool Calling.
O agente interpreta a intenção do paciente e decide qual tool usar:

- buscar_faq      → Perguntas gerais (preparo exames, convênios, política)
- buscar_medico   → Dados de um médico específico (por nome, CRM, especialidade)
- buscar_horarios → Horários de atendimento de um médico
- buscar_agendamentos → Agendamentos de um paciente (por CPF)
"""

import json
import logging
from typing import Optional

from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


# ------------------------------------------------------------------ #
#  DEFINIÇÃO DAS TOOLS (JSON Schema para a LLM)
# ------------------------------------------------------------------ #

TOOLS_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "buscar_faq",
            "description": (
                "Busca na base de conhecimento (FAQ) por informações gerais como: "
                "preparo para exames, convênios aceitos, política de cancelamento, "
                "como agendar, dúvidas frequentes, localização, especialidades. "
                "Use esta ferramenta para perguntas GERAIS que não dependem de dados "
                "específicos de um médico ou paciente no banco de dados."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "pergunta": {
                        "type": "string",
                        "description": "A pergunta ou termo a buscar na FAQ"
                    },
                    "medico_id": {
                        "type": "integer",
                        "description": "ID do médico para buscar FAQ específica dele (opcional)"
                    }
                },
                "required": ["pergunta"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "buscar_medico",
            "description": (
                "Busca dados de um médico no banco de dados por nome, CRM ou especialidade. "
                "Retorna: nome completo, CRM, especialidade, telefone, bio, valor da consulta, "
                "se aceita convênio e quais. Use quando o paciente mencionar um médico "
                "específico ou perguntar sobre um profissional."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "nome": {
                        "type": "string",
                        "description": "Nome (ou parte do nome) do médico para buscar"
                    },
                    "crm": {
                        "type": "string",
                        "description": "Número do CRM do médico"
                    },
                    "especialidade": {
                        "type": "string",
                        "description": "Especialidade médica para buscar (ex: cardiologia, ortopedia)"
                    }
                },
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "buscar_horarios",
            "description": (
                "Busca os horários de atendimento e disponibilidade de um médico. "
                "Retorna os agendamentos futuros do médico para que o paciente saiba "
                "quais horários estão livres. Use quando o paciente perguntar sobre "
                "disponibilidade, horários ou quiser agendar uma consulta."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "medico_id": {
                        "type": "integer",
                        "description": "ID do médico para buscar horários"
                    },
                    "nome_medico": {
                        "type": "string",
                        "description": "Nome do médico (caso não tenha o ID)"
                    }
                },
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "buscar_agendamentos",
            "description": (
                "Busca os agendamentos (consultas) de um paciente pelo CPF. "
                "Retorna: data/hora, status, tipo, médico, motivo. "
                "Use quando o paciente quiser ver, cancelar ou remarcar suas consultas."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "cpf": {
                        "type": "string",
                        "description": "CPF do paciente (formato: 000.000.000-00 ou apenas números)"
                    }
                },
                "required": ["cpf"]
            }
        }
    }
]


# ------------------------------------------------------------------ #
#  IMPLEMENTAÇÃO DAS TOOLS
# ------------------------------------------------------------------ #

def buscar_faq(pergunta: str, medico_id: int = None, chroma_client=None) -> str:
    """
    Busca na FAQ (ChromaDB) por perguntas gerais.
    """
    import chromadb
    import os

    if chroma_client is None:
        chroma_dir = os.environ.get(
            "CHROMA_DIR",
            os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data")
        )
        chroma_client = chromadb.PersistentClient(path=chroma_dir)

    collection_name = f"faq_doctor_{medico_id}" if medico_id else "faq_doctor_0"

    try:
        collection = chroma_client.get_collection(collection_name)
    except Exception:
        # Fallback
        try:
            collection = chroma_client.get_collection("faq_doctor_0")
        except Exception:
            try:
                collection = chroma_client.get_collection("faq_doctor_1")
            except Exception:
                return "Nenhuma base de FAQ encontrada. A FAQ ainda não foi indexada."

    if collection.count() == 0:
        return "A base de FAQ está vazia. Execute a indexação primeiro."

    try:
        results = collection.query(
            query_texts=[pergunta],
            n_results=min(5, collection.count())
        )
    except Exception as e:
        logger.error(f"Erro na busca FAQ: {e}")
        return f"Erro ao buscar na FAQ: {str(e)}"

    if not results or not results["documents"] or not results["documents"][0]:
        return "Nenhuma informação encontrada na FAQ para esta pergunta."

    # Formatar resultados
    chunks = []
    for i, doc in enumerate(results["documents"][0]):
        source = results["metadatas"][0][i].get("source", "FAQ") if results["metadatas"] else "FAQ"
        chunks.append(f"[Fonte: {source}]\n{doc}")

    return "\n\n---\n\n".join(chunks)


def buscar_medico(
    db: Session,
    nome: str = None,
    crm: str = None,
    especialidade: str = None
) -> str:
    """
    Busca dados do médico no PostgreSQL (tabela medicos).
    """
    from app.models.medico import Medico

    query = db.query(Medico).filter(Medico.ativo == True)

    if crm:
        query = query.filter(Medico.crm == crm)
    elif nome:
        query = query.filter(Medico.nome_completo.ilike(f"%{nome}%"))
    elif especialidade:
        query = query.filter(Medico.especialidade.ilike(f"%{especialidade}%"))
    else:
        # Sem filtros, retorna os primeiros 5
        query = query.limit(5)

    medicos = query.all()

    if not medicos:
        return "Nenhum médico encontrado com os critérios informados."

    resultados = []
    for m in medicos:
        info = {
            "id": m.id,
            "nome": m.nome_completo,
            "crm": f"{m.crm}/{m.crm_estado}",
            "especialidade": m.especialidade,
            "telefone": m.telefone or "Não informado",
            "whatsapp": m.whatsapp or "Não informado",
            "bio": m.bio_resumida or "Sem bio disponível",
            "duracao_consulta": f"{m.duracao_consulta_min} minutos",
            "valor_consulta": f"R$ {m.valor_consulta}" if m.valor_consulta else "Consultar",
            "aceita_convenio": "Sim" if m.aceita_convenio else "Não",
        }

        if m.aceita_convenio and m.convenios:
            try:
                convs = json.loads(m.convenios)
                info["convenios"] = ", ".join(convs)
            except (json.JSONDecodeError, TypeError):
                info["convenios"] = m.convenios

        resultados.append(json.dumps(info, ensure_ascii=False))

    return "\n\n".join(resultados)


def buscar_horarios(
    db: Session,
    medico_id: int = None,
    nome_medico: str = None
) -> str:
    """
    Busca horários de atendimento e agendamentos do médico.
    """
    from app.models.medico import Medico
    from app.models.appointment import Appointment
    from datetime import datetime, timedelta

    # Resolver médico
    medico = None
    if medico_id:
        medico = db.query(Medico).filter(Medico.id == medico_id, Medico.ativo == True).first()
    elif nome_medico:
        medico = db.query(Medico).filter(
            Medico.nome_completo.ilike(f"%{nome_medico}%"),
            Medico.ativo == True
        ).first()

    if not medico:
        return "Médico não encontrado. Verifique o nome ou ID informado."

    # Buscar agendamentos futuros (próximos 30 dias)
    agora = datetime.utcnow()
    ate = agora + timedelta(days=30)

    agendamentos = db.query(Appointment).filter(
        Appointment.medico_id == medico.id,
        Appointment.appointment_date >= agora,
        Appointment.appointment_date <= ate,
        Appointment.status.in_(["pending", "confirmed"])
    ).order_by(Appointment.appointment_date).all()

    info = {
        "medico": medico.nome_completo,
        "especialidade": medico.especialidade,
        "duracao_consulta": f"{medico.duracao_consulta_min} minutos",
        "horario_atendimento_padrao": "Segunda a Sexta, das 08:00 às 18:00",
        "dias_disponiveis": "O médico atende de segunda a sexta-feira. Sábados, domingos e feriados não há atendimento.",
    }

    if agendamentos:
        ocupados = []
        for ag in agendamentos:
            ocupados.append(
                ag.appointment_date.strftime("%d/%m/%Y %H:%M")
            )
        info["horarios_ocupados_proximos_30_dias"] = ocupados
        info["total_agendamentos"] = len(agendamentos)
    else:
        info["disponibilidade"] = "Sem agendamentos nos próximos 30 dias — agenda livre"

    return json.dumps(info, ensure_ascii=False)


def buscar_agendamentos(db: Session, cpf: str) -> str:
    """
    Busca agendamentos de um paciente pelo CPF.
    """
    from app.models.patient import Patient
    from app.models.appointment import Appointment
    from app.models.medico import Medico

    # Limpar CPF (apenas números)
    cpf_limpo = "".join(c for c in cpf if c.isdigit())
    
    # Banco pode ter CPF formatado (123.456.789-00) ou apenas números
    cpf_formatado = ""
    if len(cpf_limpo) == 11:
        cpf_formatado = f"{cpf_limpo[:3]}.{cpf_limpo[3:6]}.{cpf_limpo[6:9]}-{cpf_limpo[9:]}"

    # Buscar paciente
    patient = db.query(Patient).filter(
        (Patient.cpf == cpf_limpo) | (Patient.cpf == cpf_formatado) | (Patient.cpf == cpf)
    ).first()

    if not patient:
        return f"Nenhum paciente encontrado com CPF {cpf}. Verifique se o CPF está correto."

    # Buscar agendamentos
    agendamentos = db.query(Appointment).filter(
        Appointment.patient_id == patient.id
    ).order_by(Appointment.appointment_date.desc()).limit(10).all()

    if not agendamentos:
        return f"Paciente {patient.name} encontrado, mas não possui agendamentos registrados."

    resultado = {
        "paciente": patient.name,
        "total_agendamentos": len(agendamentos),
        "agendamentos": []
    }

    for ag in agendamentos:
        entry = {
            "data_hora": ag.appointment_date.strftime("%d/%m/%Y %H:%M"),
            "status": ag.status,
            "tipo": ag.type or "consulta",
            "motivo": ag.reason or "Não informado",
        }

        # Buscar nome do médico
        if ag.medico_id:
            medico = db.query(Medico).filter(Medico.id == ag.medico_id).first()
            if medico:
                entry["medico"] = medico.nome_completo

        resultado["agendamentos"].append(entry)

    return json.dumps(resultado, ensure_ascii=False)


# ------------------------------------------------------------------ #
#  EXECUTOR DE TOOLS
# ------------------------------------------------------------------ #

def execute_tool(tool_name: str, arguments: dict, db: Session) -> str:
    """
    Executa uma tool pelo nome e retorna o resultado como string.
    
    Args:
        tool_name: Nome da função a executar
        arguments: Argumentos da função (vindos da LLM)
        db: Sessão do banco de dados
        
    Returns:
        Resultado da execução como string
    """
    logger.info(f"Executando tool: {tool_name}({arguments})")

    try:
        if tool_name == "buscar_faq":
            return buscar_faq(
                pergunta=arguments.get("pergunta", ""),
                medico_id=arguments.get("medico_id")
            )

        elif tool_name == "buscar_medico":
            return buscar_medico(
                db=db,
                nome=arguments.get("nome"),
                crm=arguments.get("crm"),
                especialidade=arguments.get("especialidade")
            )

        elif tool_name == "buscar_horarios":
            return buscar_horarios(
                db=db,
                medico_id=arguments.get("medico_id"),
                nome_medico=arguments.get("nome_medico")
            )

        elif tool_name == "buscar_agendamentos":
            return buscar_agendamentos(
                db=db,
                cpf=arguments.get("cpf", "")
            )

        else:
            return f"Tool '{tool_name}' não reconhecida."

    except Exception as e:
        logger.error(f"Erro ao executar tool {tool_name}: {e}")
        return f"Erro ao executar {tool_name}: {str(e)}"
