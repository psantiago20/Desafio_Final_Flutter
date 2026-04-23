import httpx
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)


class WhatsAppService:
    def __init__(self):
        self.base_url = "https://graph.facebook.com/v25.0"
        self.phone_number_id = settings.WHATSAPP_PHONE_NUMBER_ID
        self.access_token = settings.WHATSAPP_ACCESS_TOKEN
    
    async def send_message(self, to: str, message: str) -> dict:
        url = f"{self.base_url}/{self.phone_number_id}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": message}
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                logger.info(f"Meta API Status Code: {response.status_code}")
                logger.info(f"Meta API Response: {response.text}")
                response.raise_for_status()
                logger.info(f"Message sent successfully to {to}")
                return response.json()
            except httpx.HTTPStatusError as e:
                error_detail = e.response.json()
                logger.error(f"Meta API Error (Send Message): {error_detail}")
                raise
            except Exception as e:
                logger.error(f"Unexpected error in send_message: {e}")
                raise


    
    async def send_template(self, to: str, template_name: str, language: str = "en_US") -> dict:
        url = f"{self.base_url}/{self.phone_number_id}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": to,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {"code": language}
            }
        }
        
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                response.raise_for_status()
                logger.info(f"Template sent to {to}")
                return response.json()
            except httpx.HTTPStatusError as e:
                error_detail = e.response.json()
                logger.error(f"Meta API Error (Template): {error_detail}")
                raise

            except Exception as e:
                logger.error(f"Unexpected error sending template: {e}")
                raise


wa_service = WhatsAppService()