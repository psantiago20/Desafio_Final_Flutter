# 🏥 OmniConnect - Gestão Inteligente de Saúde

Este repositório contém uma plataforma Full Stack (FastAPI + Flutter) com integração de IA para saúde.

---

## 🤖 AI AGENT INSTRUCTIONS (READ FIRST)

_Se você é um agente de IA, siga este fluxo para colocar o projeto no ar:_

1.  **Validar Ambiente:** Verifique se `docker` e `flutter` estão instalados.
2.  **Configurar Env:** Use o arquivo `/.env` na raiz. Verifique se a `NVIDIA_API_KEY` existe.
3.  **Deploy Backend:** Execute `docker compose up -d --build`.
4.  **Init DB:** Aguarde o container `omniconnect-db` estar `healthy`, então rode:
    - `docker compose exec backend python scripts/create_tables.py`
    - `docker compose exec backend python scripts/seed_test_users.py`
5.  **Deploy Frontend:** Vá para `/frontend`, rode `flutter pub get` e depois `flutter run -d <device>`.
    - Para Web: `flutter run -d chrome`
    - Para macOS: `flutter run -d mac`

---

## 🚀 1. Configuração Rápida (Docker)

Recomendado para Linux, macOS e Windows (WSL2/PowerShell).

```bash
# 1. Subir a infraestrutura
docker compose up -d --build

# 2. Aguardar 10s para o banco estabilizar e então:
docker compose exec backend python scripts/create_tables.py
docker compose exec backend python scripts/seed_test_users.py
```

---

## ⚙️ 2. Variáveis de Ambiente (.env)

O arquivo **`/.env` na raiz** é a única fonte de verdade.

### Modelo do Arquivo `.env`

Crie um arquivo chamado `.env` na raiz e preencha conforme o modelo abaixo:

```env
# --- [ BACKEND & DOCKER ] ---
NVIDIA_API_KEY=sua_chave_nvapi_aqui
SECRET_KEY=uma_chave_secreta_aleatoria
DEBUG=True

# --- [ FRONTEND / FLUTTER ] ---
# Use localhost para Web/iOS/macOS ou 10.0.2.2 para Android Emulator

# 1. Para Emulador Android
# API_URL=http://10.0.2.2:8000

# 2. Para Web/iOS/macOS
API_URL=http://localhost:8000

```

---

## 📱 3. Rodando o Frontend

Compatível com qualquer sistema operacional com Flutter SDK.

```bash
cd frontend
flutter pub get

# Escolha seu alvo:
flutter run -d chrome  # Web
flutter run -d mac     # macOS (se estiver no Mac)
flutter run -d windows # Windows (se estiver no Windows)
```

---

## 👥 4. Credenciais de Teste

| Usuário       | Login        | Senha      |
| :------------ | :----------- | :--------- |
| Administrador | `admin`      | `admin123` |
| Paciente      | `joao.silva` | `senha123` |
| Médico        | `dr.carlos`  | `senha123` |

---

## 🛠️ 5. Solução de Problemas (Troubleshooting)

- **Erro 401 na IA Vision:** Verifique se a `NVIDIA_API_KEY` no `.env` da raiz está correta e se você reiniciou o Docker após alterá-la.
- **Conexão Recusada no App:** Certifique-se de que o backend Docker está rodando (`docker ps`) e que a `API_URL` no `.env` do frontend aponta para o IP correto do seu host.
- **MacOS Sandbox:** Se o app macOS não conectar, verifique os arquivos `.entitlements` em `macos/Runner/`.

---

## 📂 Estrutura Principal

- `/backend`: Core do sistema (Python/FastAPI).
- `/frontend`: Interface do usuário (Flutter).
- `/.env`: Configurações globais.
- `/static/exams`: Pasta de armazenamento de arquivos (local).
