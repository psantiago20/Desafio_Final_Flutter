import requests
import json

base_url = "http://localhost:8000"

def get_messages():
    # Login as patient
    login_data = {
        "username": "thorne.blackwood",
        "password": "senha123"
    }
    r = requests.post(f"{base_url}/api/auth/login", data=login_data)
    if r.status_code != 200:
        print(f"Login failed: {r.text}")
        return
    
    token = r.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    r = requests.get(f"{base_url}/api/messages?patient_id=1", headers=headers)
    print(f"Messages Response: {r.status_code}")
    messages = r.json()["messages"][:10]
    for m in messages:
        print(json.dumps({
            "id": m.get("id"),
            "sender_id": m.get("sender_id"),
            "receiver_id": m.get("receiver_id"),
            "source": m.get("source"),
            "content": m.get("content"),
            "wa_from": m.get("wa_from"),
            "created_at": m.get("created_at")
        }, indent=2))

if __name__ == "__main__":
    get_messages()
