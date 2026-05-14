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
    },
    {
        "type": "function",
        "function": {
            "name": "listar_especialidades",
            "description": (
                "Lista todas as especialidades médicas atendidas na clínica. "
                "Use esta ferramenta quando o paciente perguntar 'quais especialidades vocês atendem?', "
                "'quais médicos tem?' ou se ele estiver em dúvida sobre qual profissional procurar."
            ),
            "parameters": {
                "type": "object",
                "properties": {},
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "agendar_consulta",
            "description": (
                "Realiza o agendamento de uma consulta no banco de dados. "
                "Requer o ID do médico, a data/hora desejada e o CPF do paciente. "
                "Se o CPF não for fornecido, a ferramenta tentará buscar no estado da conversa."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "medico_id": {
                        "type": "integer",
                        "description": "ID do médico para o agendamento"
                    },
                    "data_hora": {
                        "type": "string",
                        "description": "Data e hora no formato ISO (AAAA-MM-DD HH:MM)"
                    },
                    "cpf": {
                        "type": "string",
                        "description": "CPF do paciente (opcional se já coletado)"
                    },
                    "motivo": {
                        "type": "string",
                        "description": "Motivo da consulta (opcional)"
                    }
                },
                "required": ["medico_id", "data_hora"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "cancelar_consulta",
            "description": (
                "Cancela o agendamento de uma consulta no banco de dados. "
                "Requer a data/hora original da consulta. "
                "Se o CPF não for fornecido, a ferramenta tentará buscar no estado da conversa."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "data_hora": {
                        "type": "string",
                        "description": "Data e hora originais do agendamento (AAAA-MM-DD HH:MM)"
                    },
                    "cpf": {
                        "type": "string",
                        "description": "CPF do paciente (opcional se já coletado)"
                    }
                },
                "required": ["data_hora"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "buscar_consultas_medico",
            "description": (
                "Busca as próximas consultas (agendamentos) de um médico. "
                "Use quando o médico perguntar sobre sua agenda, próximas consultas ou compromissos."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "medico_id": {
                        "type": "integer",
                        "description": "ID do médico para buscar consultas"
                    }
                },
                "required": ["medico_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "buscar_info_paciente",
            "description": (
                "Busca informações de um paciente e seus exames pelo nome ou CPF. "
                "Use quando o médico pedir informações sobre um paciente ou exames dele."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "nome_ou_cpf": {
                        "type": "string",
                        "description": "Nome ou CPF do paciente"
                    }
                },
                "required": ["nome_ou_cpf"]
            }
        }
    }
]

def listar_especialidades(db: Session) -> str:
    """
    Retorna a lista de especialidades baseada nos médicos cadastrados + FAQ global.
    """
    from app.models.medico import Medico
    
    # 1. Buscar no Banco de Dados (Dinâmico)
    try:
        medicos = db.query(Medico).filter(Medico.ativo == True).all()
        especialidades_db = sorted(list(set([m.especialidade for m in medicos if m.especialidade])))
    except Exception:
        especialidades_db = []

    # 2. Buscar no FAQ Global (Referência)
    faq_ref = buscar_faq("especialidades")
    
    resultado = "Aqui estão as especialidades disponíveis no momento:\n\n"
    
    if especialidades_db:
        resultado += "🩺 **Médicos em Atendimento:**\n- " + "\n- ".join(especialidades_db) + "\n\n"
    
    if "Nenhuma informação encontrada" not in faq_ref:
        resultado += "📚 **Informações Adicionais:**\n" + faq_ref
    
    if not especialidades_db and "Nenhuma informação encontrada" in faq_ref:
        return "No momento não consegui carregar a lista de especialidades. Por favor, tente novamente em instantes ou fale com nossa recepção."

    return resultado


# ------------------------------------------------------------------ #
#  IMPLEMENTAÇÃO DAS TOOLS
# ------------------------------------------------------------------ #

# Cliente ChromaDB compartilhado para evitar locks de arquivo
_CHROMA_CLIENT = None

def _get_chroma_client():
    global _CHROMA_CLIENT
    if _CHROMA_CLIENT is None:
        import os
        import chromadb
        chroma_dir = os.environ.get(
            "CHROMA_DIR",
            os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "chroma_data")
        )
        logger.info(f"Inicializando cliente ChromaDB em: {chroma_dir}")
        _CHROMA_CLIENT = chromadb.PersistentClient(path=chroma_dir)
    return _CHROMA_CLIENT


def buscar_faq(pergunta: str, medico_id: int = None, chroma_client=None) -> str:
    """
    Busca na FAQ (ChromaDB) por perguntas gerais.
    """
    if chroma_client is None:
        chroma_client = _get_chroma_client()

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
        # top_k=3: reduz tokens de contexto enviados para a LLM → geração mais rápida
        results = collection.query(
            query_texts=[pergunta],
            n_results=min(3, collection.count())
        )
    except Exception as e:
        logger.error(f"Erro na busca FAQ: {e}")
        return f"Erro ao buscar na FAQ: {str(e)}"

    if not results or not results["documents"] or not results["documents"][0]:
        return "Nenhuma informação encontrada na FAQ para esta pergunta."

    # Formatar resultados com FILTRO DE SEGURANÇA RÍGIDO (Anti-Vazamento)
    chunks = []
    FORBIDDEN_KEYWORDS = ["localhost", "11434", "ollama", "nvidia nim", "aula", "código", "python", "api", "endpoint", "npx", "uvicorn", "flutter run"]
    FORBIDDEN_SOURCES = ["aula", "code", "internal", "config", "localhost", "main.py", "service.py"]

    for i, doc in enumerate(results["documents"][0]):
        source = str(results["metadatas"][0][i].get("source", "FAQ")).lower() if results["metadatas"] else "faq"
        doc_lower = doc.lower()
        
        # Pular se a fonte ou o conteúdo for técnico/interno (Evita vazamento de dados de aula)
        if any(k in source for k in FORBIDDEN_SOURCES) or any(k in doc_lower for k in FORBIDDEN_KEYWORDS):
            logger.warning(f"[Security] Vazamento de dado técnico bloqueado! Fonte: {source}")
            continue

        source_clean = results["metadatas"][0][i].get("source", "FAQ")
        chunks.append(f"[Fonte: {source_clean}]\n{doc}")

    if not chunks:
        return "Nenhuma informação clínica disponível para esta pergunta na FAQ."

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

    try:
        query = db.query(Medico).filter(Medico.ativo == True)

        if especialidade:
            # Limpeza de termos comuns que a IA confunde com especialidade
            termos_invalidos = ["disponível", "disponivel", "livre", "agenda", "horário", "horario", "médico", "medico"]
            if especialidade.lower().strip() in termos_invalidos:
                especialidade = None

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
        logger.info(f"[DB Debug] Médicos encontrados na query: {len(medicos)}")

        if not medicos:
            return "Nenhum médico encontrado com os critérios informados."
    except Exception as e:
        db.rollback()
        logger.error(f"Erro no banco de dados em buscar_medico: {e}")
        return "Erro temporário ao acessar os dados dos médicos. Tente novamente."


    resultados = []
    for m in medicos:
        bio = m.bio_resumida or "Sem bio disponível"
        val = f"R$ {m.valor_consulta}" if m.valor_consulta else "Consultar"
        convs = m.convenios if (m.aceita_convenio and m.convenios) else "Nenhum"
        if isinstance(convs, str) and convs.startswith("["):
            try:
                convs = ", ".join(json.loads(convs))
            except Exception:
                pass
        
        info = (
            f"**{m.nome_completo}** ({m.especialidade})\n"
            f"- CRM: {m.crm}/{m.crm_estado}\n"
            f"- Status: Disponível para agendamentos\n"
            f"- Valor Consulta: {val} (Duração: {m.duracao_consulta_min} min)\n"
            f"- Convênios aceitos: {convs}\n"
            f"- Bio: {bio}"
        )
        resultados.append(info)

    return "\n\n".join(resultados)


def buscar_horarios(
    db: Session,
    medico_id: int = None,
    nome_medico: str = None
) -> str:
    """
    Busca horários de atendimento e calcula slots LIVRES do médico para os próximos 7 dias.
    """
    from app.models.medico import Medico
    from app.models.appointment import Appointment
    from datetime import datetime, timedelta, time

    # Resolver médico
    try:
        medico = None
        if medico_id:
            try:
                m_id = int(str(medico_id).strip())
                medico = db.query(Medico).filter(Medico.id == m_id, Medico.ativo == True).first()
            except (ValueError, TypeError):
                nome_para_busca = str(medico_id)
                medico = db.query(Medico).filter(Medico.nome_completo.ilike(f"%{nome_para_busca}%"), Medico.ativo == True).first()
        
        if not medico and nome_medico:
            medico = db.query(Medico).filter(Medico.nome_completo.ilike(f"%{nome_medico}%"), Medico.ativo == True).first()

        if not medico:
            return "Médico não encontrado. Por favor, especifique o nome do profissional (ex: Dra. Marina Costa ou Dr. Thorne Blackwood)."

        # Configurações de horário
        START_HOUR = 8
        END_HOUR = 18
        LUNCH_START = 12
        LUNCH_END = 13
        SLOT_DURATION = medico.duracao_consulta_min or 30

        # Buscar agendamentos existentes (próximos 5 dias)
        agora = datetime.now()
        # Buffer de 5 minutos para evitar sugerir horários que estão começando agora
        agora_com_buffer = agora + timedelta(minutes=5)
        hoje = agora.date()
        limite = hoje + timedelta(days=5)

        agendamentos = db.query(Appointment).filter(
            Appointment.medico_id == medico.id,
            Appointment.appointment_date >= hoje,
            Appointment.appointment_date <= limite,
            Appointment.status.in_(["pending", "confirmed"])
        ).all()

        ocupados = [a.appointment_date for a in agendamentos]

        # Gerar slots disponíveis (Apenas os próximos 2 dias para economia radical de tokens)
        disponibilidade = {}
        dias_a_gerar = 2
        
        for i in range(dias_a_gerar + 1):
            data_atual = hoje + timedelta(days=i)
            
            # Pular finais de semana (5=Sábado, 6=Domingo)
            if data_atual.weekday() >= 5:
                continue
                
            dia_str = data_atual.strftime("%d/%m (%A)")
            # Tradução manual simples para PT-BR
            traducoes = {
                "Monday": "Segunda", "Tuesday": "Terça", "Wednesday": "Quarta",
                "Thursday": "Quinta", "Friday": "Sexta"
            }
            for eng, pt in traducoes.items():
                dia_str = dia_str.replace(eng, pt)

            slots_do_dia = []
            
            # Gerar slots das 08h às 18h
            hora_atual = datetime.combine(data_atual, time(START_HOUR, 0))
            hora_fim = datetime.combine(data_atual, time(END_HOUR, 0))
            
            while hora_atual + timedelta(minutes=SLOT_DURATION) <= hora_fim:
                # Pular horário de almoço
                if LUNCH_START <= hora_atual.hour < LUNCH_END:
                    hora_atual += timedelta(minutes=SLOT_DURATION)
                    continue
                
                # Pular horários passados se for hoje (com buffer)
                if data_atual == hoje and hora_atual < agora_com_buffer:
                    hora_atual += timedelta(minutes=SLOT_DURATION)
                    continue
                
                # Verificar se o slot está livre
                is_free = True
                for ocupado in ocupados:
                    # Se houver sobreposição de horários
                    diff = abs((hora_atual - ocupado).total_seconds() / 60)
                    if diff < SLOT_DURATION:
                        is_free = False
                        break
                
                if is_free:
                    slots_do_dia.append(hora_atual.strftime("%H:%M"))
                
                hora_atual += timedelta(minutes=SLOT_DURATION)
            
            if slots_do_dia:
                disponibilidade[dia_str] = slots_do_dia[:3] # Limitar a 3 slots para economia radical de tokens
        
        if not disponibilidade:
            return f"No momento, o(a) {medico.nome_completo} não possui horários disponíveis para os próximos 3 dias."

        # Retornar como texto estruturado claro para a IA
        resultado = f"Horários disponíveis para {medico.nome_completo} ({medico.especialidade}):\n"
        for dia, slots in disponibilidade.items():
            resultado += f"- {dia}: {', '.join(slots)}\n"
            
        return resultado.strip()

    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao calcular horários: {e}")
        return "Desculpe, tive um erro ao consultar a agenda. Tente novamente em instantes."


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

    try:
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
    except Exception as e:
        db.rollback()
        logger.error(f"Erro no banco de dados em buscar_agendamentos: {e}")
        return "Erro temporário ao acessar os agendamentos. Tente novamente."

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


def buscar_consultas_medico(db: Session, medico_id: int) -> str:
    """
    Busca as próximas consultas (agendamentos) de um médico.
    """
    from app.models.appointment import Appointment
    from app.models.patient import Patient
    from app.models.medico import Medico
    from datetime import datetime
    
    agora = datetime.utcnow()
    try:
        # Buscar nome do médico
        medico = db.query(Medico).filter(Medico.id == medico_id).first()
        nome_medico = medico.nome_completo if medico else f"ID: {medico_id}"

        agendamentos = db.query(Appointment, Patient).join(Patient).filter(
            Appointment.medico_id == medico_id,
            Appointment.appointment_date >= agora,
            Appointment.status.in_(["pending", "confirmed"])
        ).order_by(Appointment.appointment_date.asc()).limit(20).all()
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao buscar consultas do médico: {e}")
        return "Erro ao buscar consultas do médico."

    if not agendamentos:
        return "Nenhum agendamento futuro encontrado."

    resultado = f"Próximas consultas do médico {nome_medico}:\n"
    seen = set()
    for ag, patient in agendamentos:
        # Dedup por data, paciente e motivo
        key = (ag.appointment_date, patient.name, ag.reason)
        if key not in seen:
            resultado += f"- {ag.appointment_date.strftime('%d/%m/%Y %H:%M')} | Paciente: {patient.name} | Motivo: {ag.reason or 'Não informado'}\n"
            seen.add(key)
        
    return resultado


def buscar_info_paciente(db: Session, nome_ou_cpf: str) -> str:
    """
    Busca informações de um paciente e seus exames pelo nome ou CPF.
    """
    from app.models.patient import Patient
    from app.models.exam import Exam
    
    try:
        # Limpar CPF se for o caso
        cpf_limpo = "".join(c for c in nome_ou_cpf if c.isdigit())
        
        query = db.query(Patient)
        if len(cpf_limpo) == 11:
            query = query.filter(Patient.cpf == cpf_limpo)
        else:
            query = query.filter(Patient.name.ilike(f"%{nome_ou_cpf}%"))
            
        patient = query.first()
        
        if not patient:
            return f"Paciente '{nome_ou_cpf}' não encontrado."
            
        res = f"Informações do Paciente:\n"
        res += f"Nome: {patient.name}\n"
        res += f"CPF: {patient.cpf or 'Não informado'}\n"
        res += f"Telefone: {patient.phone or 'Não informado'}\n"
        
        # Buscar exames
        exams = db.query(Exam).filter(Exam.patient_id == patient.id).all()
        if exams:
            res += "\nExames:\n"
            for ex in exams:
                res += f"- {ex.title} ({ex.created_at.strftime('%d/%m/%Y')})\n"
                if ex.summary:
                    res += f"  Resumo: {ex.summary}\n"
        else:
            res += "\nNenhum exame encontrado."
            
        return res
    except Exception as e:
        db.rollback()
        logger.error(f"Erro ao buscar info do paciente: {e}")
        return "Erro ao buscar informações do paciente."


# ------------------------------------------------------------------ #
#  EXECUTOR DE TOOLS
# ------------------------------------------------------------------ #

def execute_tool(tool_name: str, arguments: dict, db: Session, wa_from: str = None) -> str:
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
        
        elif tool_name == "agendar_consulta":
            from app.services.conversation_state import conversation_manager
            from app.models.patient import Patient
            from app.models.appointment import Appointment
            from app.models.medico import Medico
            from datetime import datetime

            medico_id = arguments.get("medico_id")
            data_hora_str = arguments.get("data_hora")
            cpf_arg = arguments.get("cpf")
            patient_name = arguments.get("patient_name")
            patient_id = arguments.get("patient_id")
            motivo = arguments.get("motivo", "Consulta via WhatsApp")

            # 0. Identificar Paciente por ID
            patient = None
            if patient_id:
                patient = db.query(Patient).filter(Patient.id == patient_id).first()
                if patient and wa_from:
                    conversation_manager.set_pending_patient_id(wa_from, patient.id)
            
            # Se não encontrou por ID passado, tenta recuperar do estado
            recovered_from_state = False
            if not patient and wa_from:
                saved_id = conversation_manager.get_pending_patient_id(wa_from)
                if saved_id:
                    patient = db.query(Patient).filter(Patient.id == saved_id).first()
                    if patient:
                        recovered_from_state = True

            # 1. Identificar Paciente (Prioridade: WhatsApp/Telefone)
            if not patient and wa_from:
                wa_digits = "".join(c for c in wa_from if c.isdigit())
                if len(wa_digits) >= 8:
                    suffix = wa_digits[-8:]
                    potential_patients = db.query(Patient).filter(
                        (Patient.whatsapp.like(f"%{suffix}%")) | 
                        (Patient.phone.like(f"%{suffix}%"))
                    ).all()

                    if potential_patients:
                        # Priorizar o que NÃO tem "WhatsApp User" no nome e tem CPF
                        for p in potential_patients:
                            if p.name and "WhatsApp User" not in p.name:
                                patient = p
                                if p.cpf: break
                        if not patient:
                            patient = potential_patients[0]
            
            # 2. Se não achou por telefone, tentar pelo CPF (se fornecido ou já coletado)
            if not patient:
                cpf = cpf_arg or conversation_manager.get_cpf(wa_from)
                if cpf:
                    cpf_limpo = "".join(c for c in cpf if c.isdigit())
                    patient = db.query(Patient).filter(Patient.cpf == cpf_limpo).first()

            # 2.5 Se não achou por CPF, tentar pelo Nome (se fornecido)
            if not patient and patient_name:
                patients = db.query(Patient).filter(Patient.name.ilike(f"%{patient_name}%")).all()
                if len(patients) == 1:
                    patient = patients[0]
                elif len(patients) > 1:
                    # Múltiplos encontrados! Retorna lista para o usuário escolher.
                    lista_pacientes = []
                    for p in patients:
                        cpf_mask = f"***.{p.cpf[3:6]}.{p.cpf[6:9]}-**" if p.cpf and len(p.cpf) >= 9 else "Não informado"
                        lista_pacientes.append(f"- **{p.name}** (ID: {p.id}, CPF: {cpf_mask})")
                    lista_str = "\n".join(lista_pacientes)
                    return f"Encontrei múltiplos pacientes com o nome '{patient_name}'. Por favor, confirme qual deles informando o ID ou CPF:\n{lista_str}"

            # 3. Se ainda não achou, pedir o CPF
            if not patient:
                if wa_from and wa_from.startswith("user_"):
                    return f"Não encontrei um paciente cadastrado com o CPF {cpf_arg or 'fornecido'}. Por favor, verifique o CPF ou cadastre o paciente primeiro no menu Prontuários."
                
                conversation_manager.set_awaiting_cpf(wa_from, "agendamento")
                from app.services.standard_messages import get_cpf_request_message
                return get_cpf_request_message("agendamento")

            # 0.1 Forçar Confirmação para Médicos (Agora que temos o paciente)
            if wa_from and wa_from.startswith("user_"):
                # Etapa 1: Confirmar Paciente (Apenas se buscou por nome puro!)
                if not patient_id and not cpf_arg and not recovered_from_state:
                    if not conversation_manager.is_awaiting_patient_confirmation(wa_from):
                        conversation_manager.set_awaiting_patient_confirmation(wa_from, True)
                        cpf_mask = f"***.{patient.cpf[3:6]}.{patient.cpf[6:9]}-**" if patient.cpf and len(patient.cpf) >= 9 else "Não informado"
                        return f"Encontrei o paciente **{patient.name}** (CPF: {cpf_mask}). Confirma que é para ele?"
                    else:
                        conversation_manager.set_awaiting_patient_confirmation(wa_from, False)

                # Etapa 2: Pedir Data se não houver
                if not data_hora_str or data_hora_str.strip() == "" or any(c.isalpha() for c in data_hora_str.replace('Z', '').replace('T', '')):
                    return f"Para qual data e horário deseja agendar para **{patient.name}**?"

                if not conversation_manager.is_awaiting_confirmation(wa_from):
                    conversation_manager.set_awaiting_confirmation(wa_from, True)
                    
                    # Formatar data para padrão brasileiro
                    data_hora_br = data_hora_str
                    try:
                        dt = None
                        for fmt in ["%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"]:
                            try:
                                dt = datetime.strptime(data_hora_str.split('.')[0].replace('Z', ''), fmt)
                                break
                            except: continue
                        
                        if not dt:
                            dt = datetime.fromisoformat(data_hora_str.replace('Z', '+00:00'))
                            
                        data_hora_br = dt.strftime("%d/%m/%Y às %H:%M")
                    except:
                        pass
                        
                    return f"Posso agendar para o paciente **{patient.name}** no dia **{data_hora_br}**? Se preferir outra data ou horário, por favor me avise. Para confirmar esta, diga 'sim' ou 'ok'."
                else:
                    conversation_manager.set_awaiting_confirmation(wa_from, False)

            # 4. Buscar médico
            medico = db.query(Medico).filter(Medico.id == medico_id, Medico.ativo == True).first()
            if not medico:
                return "Médico não encontrado. Por favor, verifique o profissional selecionado."

            # 5. Parse data
            try:
                formats = ["%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"]
                dt = None
                for fmt in formats:
                    try:
                        dt = datetime.strptime(data_hora_str.split('.')[0].replace('Z', ''), fmt)
                        break
                    except: continue
                
                if not dt:
                    dt = datetime.fromisoformat(data_hora_str.replace('Z', '+00:00'))
            except:
                return f"Não consegui entender a data '{data_hora_str}'. Por favor, use o formato AAAA-MM-DD HH:MM."

                # 6. Criar agendamento
            try:
                # O model Appointment exige doctor_id (FK para User) e aceita medico_id (FK para Medico)
                # Tentamos usar o user_id vinculado ao médico, ou um fallback seguro (ID 1)
                
                # Debug log to catch why it might be None
                m_user_id = getattr(medico, "user_id", None)
                logger.info(f"[agendar_consulta] Medico ID: {medico.id}, User ID in Medico: {m_user_id}")
                
                doctor_id_to_use = m_user_id or 1
                
                new_app = Appointment(
                    patient_id=patient.id,
                    doctor_id=doctor_id_to_use,
                    medico_id=medico.id,
                    appointment_date=dt,
                    duration_minutes=medico.duracao_consulta_min or 30,
                    status="confirmed",
                    type="consultation",
                    reason=motivo
                )
                db.add(new_app)
                db.commit()
                db.refresh(new_app)
                
                if wa_from:
                    conversation_manager.clear_pending_patient_id(wa_from)
                
                return f"✅ Consulta agendada com sucesso!\n\n🩺 **Médico:** {medico.nome_completo}\n📅 **Data:** {dt.strftime('%d/%m/%Y')}\n⏰ **Horário:** {dt.strftime('%H:%M')}\n👤 **Paciente:** {patient.name} ✨"
            except Exception as e:
                db.rollback()
                logger.error(f"Erro ao salvar agendamento: {e}")
                return "Puxa, tive um probleminha técnico ao salvar sua consulta no sistema. 😅 Por favor, tente novamente em instantes ou fale com nossa recepção."

        elif tool_name == "cancelar_consulta":
            from app.services.conversation_state import conversation_manager
            from app.models.patient import Patient
            from app.models.appointment import Appointment
            from datetime import datetime, timedelta

            data_hora_str = arguments.get("data_hora")
            cpf_arg = arguments.get("cpf")

            # 1. Identificar Paciente (Prioridade: WhatsApp/Telefone)
            patient = None
            if wa_from:
                wa_digits = "".join(c for c in wa_from if c.isdigit())
                if len(wa_digits) >= 8:
                    suffix = wa_digits[-8:]
                    potential_patients = db.query(Patient).filter(
                        (Patient.whatsapp.like(f"%{suffix}%")) | 
                        (Patient.phone.like(f"%{suffix}%"))
                    ).all()

                    if potential_patients:
                        for p in potential_patients:
                            if p.name and "WhatsApp User" not in p.name:
                                patient = p
                                if p.cpf: break
                        if not patient:
                            patient = potential_patients[0]
            
            # 2. Se não achou por telefone, tentar pelo CPF
            if not patient:
                cpf = cpf_arg or conversation_manager.get_cpf(wa_from)
                if cpf:
                    cpf_limpo = "".join(c for c in cpf if c.isdigit())
                    patient = db.query(Patient).filter(Patient.cpf == cpf_limpo).first()

            if not patient:
                conversation_manager.set_awaiting_cpf(wa_from, "cancelamento")
                from app.services.standard_messages import get_cpf_request_message
                return get_cpf_request_message("cancelamento")

            # 3. Parse data
            try:
                formats = ["%Y-%m-%d %H:%M", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M"]
                dt = None
                for fmt in formats:
                    try:
                        dt = datetime.strptime(data_hora_str.split('.')[0].replace('Z', ''), fmt)
                        break
                    except: continue
                
                if not dt:
                    dt = datetime.fromisoformat(data_hora_str.replace('Z', '+00:00'))
            except:
                return f"Não consegui entender a data '{data_hora_str}'. Por favor, use o formato AAAA-MM-DD HH:MM."

            # 4. Encontrar e cancelar agendamento
            # Usaremos um intervalo de +/- 15 minutos em torno da data informada para ser seguro
            try:
                start_dt = dt - timedelta(minutes=15)
                end_dt = dt + timedelta(minutes=15)
                
                appointment = db.query(Appointment).filter(
                    Appointment.patient_id == patient.id,
                    Appointment.appointment_date >= start_dt,
                    Appointment.appointment_date <= end_dt,
                    Appointment.status.in_(["pending", "confirmed"])
                ).first()
                
                if not appointment:
                    return f"Não encontrei nenhuma consulta agendada para {patient.name} perto de {dt.strftime('%d/%m/%Y %H:%M')}."

                # Apagar do banco de dados (Hard delete para não aparecer no app)
                db.delete(appointment)
                db.commit()
                
                return f"✅ Consulta de {patient.name} do dia {dt.strftime('%d/%m/%Y')} às {dt.strftime('%H:%M')} cancelada com sucesso! ✨"
                
            except Exception as e:
                db.rollback()
                logger.error(f"Erro ao cancelar agendamento: {e}")
                return "Tive um problema técnico ao tentar cancelar sua consulta. 😅 Por favor, tente novamente em instantes ou fale com a recepção."

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

        elif tool_name == "listar_especialidades":
            return listar_especialidades(db=db)

        elif tool_name == "buscar_consultas_medico":
            return buscar_consultas_medico(
                db=db,
                medico_id=arguments.get("medico_id")
            )

        elif tool_name == "buscar_info_paciente":
            return buscar_info_paciente(
                db=db,
                nome_ou_cpf=arguments.get("nome_ou_cpf")
            )

        else:
            return f"Tool '{tool_name}' não reconhecida."

    except Exception as e:
        logger.error(f"Erro ao executar tool {tool_name}: {e}")
        return f"Erro ao executar {tool_name}: {str(e)}"
