import httpx
import os
from dotenv import load_dotenv

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

TOKEN = os.getenv("WHATSAPP_ACCESS_TOKEN")
PHONE_ID = os.getenv("WHATSAPP_PHONE_NUMBER_ID")
TO = "5515981829743"

url = f"https://graph.facebook.com/v25.0/{PHONE_ID}/messages"
headers = {
    "Authorization": f"Bearer {TOKEN}",
    "Content-Type": "application/json"
}

# Teste com template hello_world
payload = {
    "messaging_product": "whatsapp",
    "to": TO,
    "type": "template",
    "template": {
        "name": "hello_world",
        "language": {"code": "en_US"}
    }
}

logger.info(f"Enviando para {TO}...")
response = httpx.post(url, json=payload, headers=headers, timeout=30.0)
logger.info(f"Status: {response.status_code}")
logger.info(f"Response: {response.text}")

if response.status_code == 200:
    print("\n✅ Template enviado com sucesso!")
    print("Verifique seu WhatsApp agora.")
else:
    print(f"\n❌ Erro: {response.status_code}")
    print(response.text)