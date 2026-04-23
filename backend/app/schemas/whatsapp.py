from pydantic import BaseModel
from typing import Optional


class WhatsAppMessage(BaseModel):
    messaging_product: str = "whatsapp"
    to: str
    type: str = "text"
    text: Optional[dict] = None
    image: Optional[dict] = None
    audio: Optional[dict] = None
    document: Optional[dict] = None


class WhatsAppWebhookPayload(BaseModel):
    object: str
    entry: list[dict]


class WhatsAppTextMessage(BaseModel):
    body: str


class WhatsAppInteractiveMessage(BaseModel):
    type: str
    button_reply: Optional[dict] = None
    list_reply: Optional[dict] = None


class WhatsAppSendResponse(BaseModel):
    messaging_product: str
    to: str
    messages: list[dict]