# 🐳 Guia de Configuração OmniConnect (Docker)

Este guia contém os passos necessários para configurar o ambiente de desenvolvimento local utilizando Docker.

## 🚀 1. Subindo o Ambiente

Certifique-se de estar na raiz do projeto (onde está o `docker-compose.yml`) e execute:

```bash
docker compose up -d --build
```

> **Nota:** O parâmetro `--build` é essencial para garantir que todas as dependências (como `email-validator`, `bcrypt` e `langchain-groq`) sejam instaladas corretamente.

---

## 🗄️ 2. Configurando o Banco de Dados (Tabelas e Seed)

Após os containers subirem, você precisa criar as tabelas e injetar os usuários de teste. Execute os comandos abaixo na ordem:

### A. Criar as Tabelas
```bash
docker compose exec backend sh -c "export PYTHONPATH=$PYTHONPATH:/app && python scripts/create_tables.py"
```

### B. Injetar Dados de Teste (Seed)
```bash
docker compose exec backend sh -c "export PYTHONPATH=$PYTHONPATH:/app && python scripts/seed_test_users.py"
```

**Usuários Criados:**
*   **Paciente:** `paciente@teste.com` / `senha123`
*   **Médico:** `medico@teste.com` / `senha123`

---

## 🔑 3. Configuração de Variáveis de Ambiente (.env)

### Backend (`backend/.env`)
O backend já possui as variáveis configuradas no `docker-compose.yml`, mas para rodar scripts locais ou ferramentas de debug, utilize:
```env
DATABASE_URL=postgresql://omniconnect:omniconnect123@localhost:5432/omniconnect
NVIDIA_API_KEY=sua_chave_aqui
DEBUG=True
```

### Frontend (`frontend/assets/.env`)
Este arquivo é **obrigatório** para o Flutter saber onde está a API. Crie o arquivo em `frontend/assets/.env`:

*   **Para Flutter Web:**
    ```env
    API_URL=http://localhost:8000
    ```
*   **Para Emulador Android:**
    ```env
    API_URL=http://10.0.2.2:8000
    ```

> **Atenção:** Após alterar o `.env` no frontend, você deve **reiniciar** o app Flutter (Stop e Start) para que as mudanças façam efeito.

---

## 🌐 4. Dicas para Flutter Web (CORS)

Se ao tentar logar via Web você receber um erro de `Failed to fetch`, é provável que o navegador esteja bloqueando a conexão por CORS. Para contornar isso em desenvolvimento, rode o app com:

```bash
flutter run -d chrome --web-renderer html --web-browser-flag "--disable-web-security"
```

---

## 🛠️ Comandos Úteis

*   **Ver Logs:** `docker compose logs -f backend`
*   **Parar Tudo:** `docker compose down`
*   **Resetar Banco:** `docker compose down -v` (apaga os dados do volume)
