import random
import string
import logging
from datetime import datetime, timedelta
from typing import Optional

logger = logging.getLogger(__name__)

class EmailService:
    @staticmethod
    def generate_verification_code(length: int = 6) -> str:
        """Gera um código numérico aleatório."""
        return ''.join(random.choices(string.digits, k=length))

    @staticmethod
    async def send_verification_email(email: str, code: str):
        """
        Simula o envio de e-mail. 
        Em produção, aqui integraria com SendGrid, Mailgun ou SMTP.
        """
        logger.info(f"--- SIMULAÇÃO DE E-MAIL ---")
        logger.info(f"Para: {email}")
        logger.info(f"Assunto: Seu código de verificação OmniConnect")
        logger.info(f"Corpo: Olá! Seu código de verificação é: {code}. Ele expira em 10 minutos.")
        logger.info(f"---------------------------")
        
        # Opcional: Salvar em um arquivo de log específico para facilitar o teste pelo desenvolvedor
        with open("email_debug.log", "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now()}] To: {email} | Code: {code}\n")

email_service = EmailService()
