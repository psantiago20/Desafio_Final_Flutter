import requests
import json

# Login first to get token
BASE_URL = "http://localhost:8000"



def test_stats():
    print("Tentando login...")
    login_resp = requests.post(f"{BASE_URL}/api/auth/login", data={
        "username": "maria.silva",
        "password": "senha123"
    })
    
    if login_resp.status_code != 200:
        print(f"Falha no login: {login_resp.text}")
        return

    token = login_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Buscando stats...")
    stats_resp = requests.get(f"{BASE_URL}/api/dashboard/stats", headers=headers)
    
    if stats_resp.status_code == 200:
        print("Stats recebidos:")
        print(json.dumps(stats_resp.json(), indent=2))
    else:
        print(f"Erro ao buscar stats: {stats_resp.status_code}")
        print(stats_resp.text)

if __name__ == "__main__":
    test_stats()
