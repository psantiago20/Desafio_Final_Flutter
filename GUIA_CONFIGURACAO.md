# Guia de Configuração - OmniConnect

Este guia detalha os passos necessários para configurar e rodar o projeto do zero para novos desenvolvedores.

## 1. Clonando o Repositório
```bash
git clone https://github.com/usuario/omniconnect.git
cd omniconnect
```

## 2. Configuração do Backend (Python)

### Ambiente Virtual
Recomendamos o uso de um ambiente virtual para isolar as dependências.
```bash
# Na raiz do projeto
python -m venv .venv

# Ativação (Windows)
.\.venv\Scripts\activate

# Ativação (Linux/Mac)
source .venv/bin/activate
```

### Instalação de Dependências
```bash
pip install -r requirements.txt
```

### Variáveis de Ambiente
O projeto utiliza um arquivo `.env` centralizado na raiz.
1. Copie o arquivo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```
2. Abra o arquivo `.env` e preencha as seguintes chaves obrigatórias:
   - `DATABASE_URL`: URL de conexão com seu PostgreSQL local.
   - `NVIDIA_API_KEY`: Sua chave da NVIDIA AI (Llama 3.1).
   - `GROQ_API_KEY`: Sua chave do Groq (LPU Engine).
   - `WHATSAPP_ACCESS_TOKEN`: Token temporário ou permanente da Meta Business.

### Banco de Dados
Certifique-se que o PostgreSQL está rodando. Execute os scripts iniciais:
```bash
# Entrar na pasta do backend para garantir os paths
cd backend

# Criar o banco e as tabelas
python scripts/create_db.py
python scripts/create_tables.py

# (Opcional) Popular com dados de teste
python scripts/seed_db.py
```

### Executando o Servidor
```bash
# Dentro da pasta backend/
uvicorn app.main:app --reload
```

## 3. Configuração do Frontend (Flutter)

1. Certifique-se de ter o Flutter instalado (`flutter doctor`).
2. Entre na pasta do frontend:
   ```bash
   cd frontend
   ```
3. Instale as dependências:
   ```bash
   flutter pub get
   ```
4. Execute o projeto (Web ou Mobile):
   ```bash
   flutter run -d chrome
   ```

## 4. Testando o WhatsApp (Simulador)
Se você não tiver acesso imediato à API da Meta, pode usar o simulador web:
1. Com o backend rodando, acesse: `http://localhost:8000/static/chat_simulator.html`
2. Ou use a versão Flutter rodando no Chrome.

## 5. Observabilidade (LangSmith)
Para debugar os agentes e o RAG:
1. Crie uma conta em [smith.langchain.com](https://smith.langchain.com/).
2. Adicione sua `LANGSMITH_API_KEY` ao `.env`.
3. Todas as chamadas de IA serão rastreadas automaticamente.

---
**Suporte:** Caso encontre erros de importação, verifique se o seu `PYTHONPATH` inclui a pasta `backend`.
