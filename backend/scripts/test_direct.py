import requests

url = "http://127.0.0.1:8000/api/webhooks/chat-direct"
payload = {
    "to": "5511988888888",
    "message": "Médicos",
    "wa_to": "5511912345678"
}
try:
    response = requests.post(url, json=payload, timeout=30)
    print("Status Code:", response.status_code)
    print("Response Body:", response.text)
except Exception as e:
    print("Error:", e)
