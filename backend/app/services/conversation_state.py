"""
conversation_state.py — Gerenciador de Estado de Conversa

Mantém o estado de cada conversa ativa por número WhatsApp (wa_from).
Usado para:
- Detectar primeira interação ou inatividade > 1h → enviar boas-vindas
- Fluxo obrigatório de CPF → aguardar CPF antes de executar operações
- Armazenar CPF coletado para uso nas tools

Estado armazenado em memória (dict). Em produção, migrar para Redis/DB.
"""

import logging
from datetime import datetime, timedelta
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)

# Tempo de inatividade para reenviar boas-vindas (em segundos)
INACTIVITY_TIMEOUT_SECONDS = 3600  # 1 hora


class ConversationState:
    """Estado de uma conversa individual."""

    def __init__(self):
        self.last_interaction_at: Optional[datetime] = None
        self.cpf_coletado: Optional[str] = None
        self.aguardando_cpf: bool = False
        self.aguardando_confirmacao: bool = False
        self.aguardando_confirmacao_paciente: bool = False
        self.operacao_pendente: Optional[str] = None  # "agendamento", "cancelamento", "consulta_agendamentos"
        self.mensagem_pendente: Optional[str] = None   # mensagem original que disparou o pedido de CPF
        self.boas_vindas_enviada: bool = False
        self.patient_id_pendente: Optional[int] = None

    def to_dict(self) -> dict:
        # Mascarar CPF para evitar vazamento em APIs de debug
        masked_cpf = None
        if self.cpf_coletado and len(self.cpf_coletado) == 11:
            masked_cpf = f"***.{self.cpf_coletado[3:6]}.***-{self.cpf_coletado[9:]}"
        elif self.cpf_coletado:
            masked_cpf = "***"

        return {
            "last_interaction_at": self.last_interaction_at.isoformat() if self.last_interaction_at else None,
            "cpf_coletado": masked_cpf,
            "aguardando_cpf": self.aguardando_cpf,
            "operacao_pendente": self.operacao_pendente,
            "boas_vindas_enviada": self.boas_vindas_enviada,
            "patient_id_pendente": self.patient_id_pendente,
        }


class ConversationManager:
    """
    Gerencia estados de conversa por número WhatsApp.
    
    Cada wa_from (número do paciente) tem seu próprio ConversationState.
    """

    def __init__(self):
        self._states: Dict[str, ConversationState] = {}

    def _get_or_create(self, wa_from: str) -> ConversationState:
        """Retorna o estado existente ou cria um novo."""
        if wa_from not in self._states:
            self._states[wa_from] = ConversationState()
        return self._states[wa_from]

    def is_first_or_inactive(self, wa_from: str) -> bool:
        """
        Verifica se é a primeira interação do paciente ou se ele
        ficou inativo por mais de INACTIVITY_TIMEOUT_SECONDS.
        
        Returns:
            True se deve enviar mensagem de boas-vindas
        """
        state = self._get_or_create(wa_from)

        # Primeira interação (nunca interagiu)
        if state.last_interaction_at is None:
            logger.info(f"[ConvState] {wa_from}: primeira interação")
            return True

        # Verificar inatividade
        elapsed = (datetime.utcnow() - state.last_interaction_at).total_seconds()
        if elapsed > INACTIVITY_TIMEOUT_SECONDS:
            logger.info(f"[ConvState] {wa_from}: inativo há {elapsed:.0f}s (>{INACTIVITY_TIMEOUT_SECONDS}s)")
            # Resetar estado quando volta após inatividade
            state.cpf_coletado = None
            state.aguardando_cpf = False
            state.operacao_pendente = None
            state.mensagem_pendente = None
            state.boas_vindas_enviada = False
            return True

        return False

    def update_activity(self, wa_from: str):
        """Atualiza o timestamp de última interação."""
        state = self._get_or_create(wa_from)
        state.last_interaction_at = datetime.utcnow()

    def mark_welcome_sent(self, wa_from: str):
        """Marca que a mensagem de boas-vindas foi enviada."""
        state = self._get_or_create(wa_from)
        state.boas_vindas_enviada = True

    def set_awaiting_cpf(self, wa_from: str, operacao: str, mensagem_original: str = None):
        """
        Marca que estamos aguardando o paciente informar o CPF.
        
        Args:
            wa_from: Número WhatsApp
            operacao: Tipo de operação ("agendamento", "cancelamento", "consulta_agendamentos")
            mensagem_original: A mensagem que o paciente enviou (para re-executar após CPF)
        """
        state = self._get_or_create(wa_from)
        state.aguardando_cpf = True
        state.operacao_pendente = operacao
        state.mensagem_pendente = mensagem_original
        logger.info(f"[ConvState] {wa_from}: aguardando CPF para '{operacao}'")

    def is_awaiting_cpf(self, wa_from: str) -> bool:
        """Verifica se estamos esperando o CPF do paciente."""
        state = self._get_or_create(wa_from)
        return state.aguardando_cpf

    def set_awaiting_confirmation(self, wa_from: str, awaiting: bool):
        """Marca se estamos aguardando confirmação de agendamento."""
        state = self._get_or_create(wa_from)
        state.aguardando_confirmacao = awaiting
        logger.info(f"[ConvState] {wa_from}: aguardando confirmação = {awaiting}")

    def is_awaiting_confirmation(self, wa_from: str) -> bool:
        """Verifica se estamos esperando confirmação."""
        state = self._get_or_create(wa_from)
        return getattr(state, "aguardando_confirmacao", False)

    def set_awaiting_patient_confirmation(self, wa_from: str, awaiting: bool):
        """Marca se estamos aguardando confirmação do paciente."""
        state = self._get_or_create(wa_from)
        state.aguardando_confirmacao_paciente = awaiting
        logger.info(f"[ConvState] {wa_from}: aguardando confirmação paciente = {awaiting}")

    def is_awaiting_patient_confirmation(self, wa_from: str) -> bool:
        """Verifica se estamos esperando confirmação do paciente."""
        state = self._get_or_create(wa_from)
        return getattr(state, "aguardando_confirmacao_paciente", False)

    def set_pending_patient_id(self, wa_from: str, patient_id: int):
        """Armazena o ID do paciente selecionado para a conversa."""
        state = self._get_or_create(wa_from)
        state.patient_id_pendente = patient_id
        logger.info(f"[ConvState] {wa_from}: patient_id pendente = {patient_id}")

    def get_pending_patient_id(self, wa_from: str) -> Optional[int]:
        """Retorna o ID do paciente selecionado."""
        state = self._get_or_create(wa_from)
        return getattr(state, "patient_id_pendente", None)

    def clear_pending_patient_id(self, wa_from: str):
        """Limpa o ID do paciente selecionado."""
        state = self._get_or_create(wa_from)
        state.patient_id_pendente = None
        logger.info(f"[ConvState] {wa_from}: patient_id pendente limpo")

    def get_cpf(self, wa_from: str) -> Optional[str]:
        """Retorna o CPF coletado (se já coletou)."""
        state = self._get_or_create(wa_from)
        return state.cpf_coletado

    def set_cpf(self, wa_from: str, cpf: str):
        """Armazena o CPF coletado e limpa flag de aguardando."""
        state = self._get_or_create(wa_from)
        state.cpf_coletado = cpf
        state.aguardando_cpf = False
        logger.info(f"[ConvState] {wa_from}: CPF coletado = {cpf[:3]}...{cpf[-2:]}")

    def get_pending_operation(self, wa_from: str) -> Optional[str]:
        """Retorna a operação pendente que aguarda CPF."""
        state = self._get_or_create(wa_from)
        return state.operacao_pendente

    def get_pending_message(self, wa_from: str) -> Optional[str]:
        """Retorna a mensagem original pendente."""
        state = self._get_or_create(wa_from)
        return state.mensagem_pendente

    def clear_cpf_flow(self, wa_from: str):
        """Limpa todas as flags do fluxo de CPF (operação concluída)."""
        state = self._get_or_create(wa_from)
        state.aguardando_cpf = False
        state.operacao_pendente = None
        state.mensagem_pendente = None

    def clear_state(self, wa_from: str):
        """Remove completamente o estado de uma conversa (para testes)."""
        if wa_from in self._states:
            del self._states[wa_from]
            logger.info(f"[ConvState] {wa_from}: estado limpo")

    def get_state(self, wa_from: str) -> dict:
        """Retorna o estado completo como dict (para debug/API)."""
        state = self._get_or_create(wa_from)
        return state.to_dict()

    def get_all_states(self) -> dict:
        """Retorna todos os estados (para debug)."""
        return {k: v.to_dict() for k, v in self._states.items()}


def validate_cpf(cpf: str) -> Optional[str]:
    """
    Valida e normaliza um CPF.
    
    Aceita formatos: 123.456.789-00, 12345678900, 123 456 789 00
    
    Returns:
        CPF normalizado (só números) se válido, None se inválido
    """
    # Limpar: remover tudo que não é número
    cpf_limpo = "".join(c for c in cpf if c.isdigit())

    # CPF deve ter 11 dígitos
    if len(cpf_limpo) != 11:
        return None

    # Rejeitar CPFs com todos os dígitos iguais (000.000.000-00 etc)
    if len(set(cpf_limpo)) == 1:
        return None

    return cpf_limpo


def looks_like_cpf(text: str) -> bool:
    """
    Verifica se o texto parece ser um CPF (heurística).
    Útil para detectar quando o paciente está respondendo com o CPF.
    """
    text = text.strip()
    
    # Formato com pontos e traço: 123.456.789-00
    import re
    if re.match(r"^\d{3}\.\d{3}\.\d{3}-\d{2}$", text):
        return True
    
    # Apenas 11 dígitos
    digits_only = "".join(c for c in text if c.isdigit())
    if len(digits_only) == 11 and len(text) <= 15:  # tolerância para espaços
        return True

    return False


# Singleton
conversation_manager = ConversationManager()
