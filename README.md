# OmniConnect - Gestão Inteligente de Serviços

Este projeto consiste em uma plataforma de gestão de pacientes e consultas com integração inteligente via WhatsApp (RAG) utilizando a API da NVIDIA (Llama 3.1) e Meta WhatsApp Business API.

## Estrutura do Projeto

- `/backend`: API FastAPI (Python 3.10+)
- `/frontend`: Aplicação Mobile/Web (Flutter)
- `/docs`: Documentação do desafio e regras de negócio
- `/scratch`: Scripts de utilidade (Extração de PDF, diagnósticos)

## Pré-requisitos

### Backend
- Python 3.10 ou superior
- PostgreSQL (Rodando na porta 5432)
- [ngrok](https://ngrok.com/) (Para expor o webhook do WhatsApp localmente)

### Frontend
- Flutter SDK (Versão estável)
- Android Emulator ou Dispositivo Físico

---

## Como Rodar o Projeto

### 1. Configuração do Backend

1. Entre na pasta do backend:
   ```bash
   cd backend
   ```
2. Crie e ative um ambiente virtual:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   .\.venv\Scripts\activate   # Windows
   ```
3. Instale as dependências:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure o arquivo `.env` na raiz do projeto:
   - Copie o arquivo `.env.example` para `.env`
   - Preencha com suas chaves (NVIDIA, Groq, WhatsApp, etc.)
5. Inicie o servidor:
   ```bash
   uvicorn app.main:app --reload
   ```

### 2. Configuração do Frontend

1. Entre na pasta do frontend:
   ```bash
   cd frontend
   ```
2. Baixe as dependências:
   ```bash
   flutter pub get
   ```
3. Execute o aplicativo:
   ```bash
   flutter run
   ```

### 3. Integração WhatsApp (Webhook)

1. Com o backend rodando, inicie o ngrok:
   ```bash
   ngrok http 8000
   ```
2. Copie a URL gerada e configure no Painel da Meta:
   `https://SUA_URL_NGROK/webhook/whatsapp`

---

## Funcionalidades Implementadas

- **Dashboard**: Monitoramento em tempo real de pacientes.
- **WhatsApp RAG**: O bot responde automaticamente usando contexto extraído de PDFs médicos (armazenados em `scratch/pdf_content.txt`).
- **Gestão de Agendamentos**: CRUD completo de consultas e pacientes.

> [!NOTE]
> Se o RAG não estiver respondendo com contexto, execute o script de extração:
> `python scratch/extract_pdf_v2.py docs/SeuArquivo.pdf scratch/pdf_content.txt`
