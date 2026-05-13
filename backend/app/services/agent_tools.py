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
            motivo = arguments.get("motivo", "Consulta via WhatsApp")

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

            # 3. Se ainda não achou, pedir o CPF
            if not patient:
                conversation_manager.set_awaiting_cpf(wa_from, "agendamento")
                from app.services.standard_messages import get_cpf_request_message
                return get_cpf_request_message("agendamento")

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
                    status="pending",
                    type="consultation",
                    reason=motivo
                )
                db.add(new_app)
                db.commit()
                db.refresh(new_app)
                
                return f"✅ Consulta agendada com sucesso!\n\n🩺 **Médico:** {medico.nome_completo}\n📅 **Data:** {dt.strftime('%d/%m/%Y')}\n⏰ **Horário:** {dt.strftime('%H:%M')}\n👤 **Paciente:** {patient.name}\n\nTe enviamos uma confirmação em breve! ✨"
            except Exception as e:
                db.rollback()
                logger.error(f"Erro ao salvar agendamento: {e}")
                return "Puxa, tive um probleminha técnico ao salvar sua consulta no sistema. 😅 Por favor, tente novamente em instantes ou fale com nossa recepção."

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

        else:
            return f"Tool '{tool_name}' não reconhecida."

    except Exception as e:
        logger.error(f"Erro ao executar tool {tool_name}: {e}")
        return f"Erro ao executar {tool_name}: {str(e)}"
