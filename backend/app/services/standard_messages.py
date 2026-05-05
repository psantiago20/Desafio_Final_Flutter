"""
standard_messages.py — Mensagens Padrão do OmniConnect

Templates de mensagens para momentos específicos da interação:
- Boas-vindas (primeira interação ou retorno após inatividade)
- Solicitação de CPF (antes de operações que exigem identificação)
- Menu de opções
- Mensagens de erro/validação
"""

import logging
from typing import Optional

logger = logging.getLogger(__name__)


def get_welcome_message(nome_medico: str, cidade: str = None) -> str:
    """
    Gera a mensagem de boas-vindas personalizada com dados do médico.
    
    Args:
        nome_medico: Nome completo do médico (ex: "Dr. Carlos Mendes")
        cidade: Cidade do consultório (ex: "São Paulo")
    
    Returns:
        Mensagem formatada para WhatsApp
    """
    cidade_text = f", em *{cidade}*" if cidade else ""
    
    return (
        f"Olá! 👋 Sou a assistente virtual da agenda do *{nome_medico}*{cidade_text}.\n\n"
        f"Estou aqui para te ajudar! Como posso ajudá-lo?\n\n"
        f"1️⃣ Tirar uma dúvida\n"
        f"2️⃣ Fazer um agendamento\n"
        f"3️⃣ Ver seus agendamentos\n"
        f"4️⃣ Cancelar uma consulta\n"
        f"5️⃣ Saber o preparo de um exame\n\n"
        f"Você pode escolher uma opção ou simplesmente digitar sua pergunta! 😊"
    )


def get_welcome_message_without_doctor() -> str:
    """
    Mensagem de boas-vindas genérica (quando o médico não é identificado).
    """
    return (
        "Olá! 👋 Sou a assistente virtual do *OmniConnect*.\n\n"
        "Estou aqui para te ajudar! Como posso ajudá-lo?\n\n"
        "1️⃣ Tirar uma dúvida\n"
        "2️⃣ Fazer um agendamento\n"
        "3️⃣ Ver seus agendamentos\n"
        "4️⃣ Cancelar uma consulta\n"
        "5️⃣ Saber o preparo de um exame\n\n"
        "Você pode escolher uma opção ou simplesmente digitar sua pergunta! 😊"
    )


def get_cpf_request_message(operacao: str) -> str:
    """
    Gera a mensagem de solicitação de CPF para uma operação específica.
    
    Args:
        operacao: Tipo de operação ("agendamento", "cancelamento", "consulta_agendamentos", "remarcacao")
    """
    operacao_labels = {
        "agendamento": "realizar o agendamento",
        "cancelamento": "cancelar sua consulta",
        "consulta_agendamentos": "consultar seus agendamentos",
        "remarcacao": "remarcar sua consulta",
    }
    
    label = operacao_labels.get(operacao, "prosseguir com sua solicitação")
    
    return (
        f"Para {label}, preciso confirmar sua identidade. 🔐\n\n"
        f"Por favor, informe seu *CPF* (formato: 000.000.000-00 ou apenas os números):"
    )


def get_cpf_invalid_message() -> str:
    """Mensagem quando o CPF informado é inválido."""
    return (
        "⚠️ O CPF informado não é válido.\n\n"
        "Por favor, digite novamente no formato:\n"
        "• *000.000.000-00* ou\n"
        "• *00000000000* (apenas números)\n\n"
        "Se preferir cancelar, digite *cancelar*."
    )


def get_cpf_confirmed_message(nome_paciente: str, operacao: str) -> str:
    """
    Mensagem de confirmação após CPF validado com sucesso.
    
    Args:
        nome_paciente: Nome do paciente encontrado no banco
        operacao: Tipo de operação que será executada
    """
    return (
        f"✅ CPF confirmado! Olá, *{nome_paciente}*!\n\n"
        f"Agora vou processar sua solicitação..."
    )


def get_cpf_not_found_message() -> str:
    """Mensagem quando o CPF não é encontrado no banco de dados."""
    return (
        "❌ Não encontrei nenhum cadastro com esse CPF.\n\n"
        "Se você ainda não é paciente, por favor entre em contato "
        "diretamente com a clínica para realizar seu cadastro.\n\n"
        "Se acredita que há um erro, verifique o CPF e tente novamente."
    )


def get_menu_message() -> str:
    """Menu principal de opções."""
    return (
        "Como posso te ajudar? Escolha uma opção:\n\n"
        "1️⃣ Tirar uma dúvida\n"
        "2️⃣ Fazer um agendamento\n"
        "3️⃣ Ver seus agendamentos\n"
        "4️⃣ Cancelar uma consulta\n"
        "5️⃣ Saber o preparo de um exame\n\n"
        "Ou simplesmente digite sua pergunta! 😊"
    )


def get_help_duvidas_message() -> str:
    """Mensagem guiada para quando o usuário escolhe 'Tirar uma dúvida' (Opção 1)."""
    return (
        "Para tirar dúvidas, você pode me fazer perguntas como:\n\n"
        "• _Qual a especialidade do médico?_\n"
        "• _Quais dias o médico atende?_\n"
        "• _O médico atende Unimed?_\n"
        "• _Qual é o endereço da clínica?_\n"
        "• _Quais são os valores das consultas?_\n\n"
        "Pode me perguntar o que quiser sobre o atendimento! 💬"
    )


def get_help_exames_message() -> str:
    """Mensagem guiada para quando o usuário escolhe 'Saber preparo de exame' (Opção 5)."""
    return (
        "Para saber o preparo de exames, me diga qual exame você vai fazer!\n"
        "Exemplos do que você pode perguntar:\n\n"
        "• _Precisa de jejum para exame de sangue?_\n"
        "• _Como me preparo para um ultrassom?_\n"
        "• _Posso tomar água antes do exame de urina?_\n\n"
        "Qual exame você deseja consultar? 🩺"
    )


def get_footer_message() -> str:
    """Rodapé padrão anexado ao final de respostas do assistente."""
    return "\n\n0️⃣ Voltar ao menu principal | ❌ Finalizar atendimento"


def detect_cpf_required_intent(message: str) -> Optional[str]:
    """
    Detecta se a mensagem do paciente indica uma operação que requer CPF.
    
    Returns:
        Tipo de operação se detectada, None caso contrário
    """
    msg_lower = message.lower().strip()
    
    # Agendamento
    agendamento_keywords = [
        "agendar", "agendamento", "marcar consulta", "marcar exame",
        "quero consulta", "quero agendar", "fazer agendamento",
        "agendar consulta", "agendar exame", "reservar horário",
        "2"  # Opção 2 do menu
    ]
    
    # Cancelamento
    cancelamento_keywords = [
        "cancelar", "cancelamento", "desmarcar", "quero cancelar",
        "cancelar consulta", "cancelar agendamento", "desmarcar consulta",
        "4"  # Opção 4 do menu
    ]
    
    # Consulta de agendamentos
    consulta_keywords = [
        "meus agendamentos", "minhas consultas", "ver agendamentos",
        "consultar agendamentos", "quais consultas", "próximas consultas",
        "ver minhas", "meus horários", "3"  # Opção 3 do menu
    ]
    
    # Remarcação
    remarcacao_keywords = [
        "remarcar", "remarcação", "mudar horário", "trocar dia",
        "trocar horário", "alterar consulta", "alterar agendamento"
    ]
    
    # Verificar cada categoria
    # Para opções numéricas ("2", "3", "4"), verificar se a mensagem é APENAS o número
    for kw in agendamento_keywords:
        if kw == "2" and msg_lower.strip() == "2":
            return "agendamento"
        elif kw != "2" and kw in msg_lower:
            return "agendamento"
    
    for kw in cancelamento_keywords:
        if kw == "4" and msg_lower.strip() == "4":
            return "cancelamento"
        elif kw != "4" and kw in msg_lower:
            return "cancelamento"
    
    for kw in consulta_keywords:
        if kw == "3" and msg_lower.strip() == "3":
            return "consulta_agendamentos"
        elif kw != "3" and kw in msg_lower:
            return "consulta_agendamentos"
    
    for kw in remarcacao_keywords:
        if kw in msg_lower:
            return "remarcacao"
    
    return None
