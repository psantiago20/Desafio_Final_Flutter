<div align="center">

# 🏥 Sua Consulta — OmniConnect

**Plataforma Full Stack de Gestão Inteligente para Clínicas Médicas**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Firebase](https://img.shields.io/badge/Firebase-FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![LangChain](https://img.shields.io/badge/LangChain-RAG-1C3C3C?style=for-the-badge&logo=chainlink&logoColor=white)](https://langchain.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

> Sistema completo para médicos gerenciarem consultas, pacientes e comunicação via IA — integrado ao WhatsApp e disponível como app mobile e web em Flutter.

</div>

---

## 📋 Sobre o Projeto

O **Sua Consulta (OmniConnect)** é uma plataforma Full Stack desenvolvida como solução ao **Desafio Tech de Gestão Inteligente de Serviços**. O sistema centraliza todo o ciclo de atendimento médico em uma única plataforma, eliminando a perda de dados em conversas de WhatsApp e organizando a agenda, pacientes e finanças do médico.

### O Problema que Resolve

| Antes | Depois |
|---|---|
| Agenda bagunçada no WhatsApp | Dashboard centralizado e organizado |
| Dados de pacientes perdidos em chats | CRM médico com histórico completo |
| Financeiro confuso e manual | Controle de receita por período e tipo |
| Triagem feita manualmente | IA (RAG) que responde e triagem automaticamente |
| Notificações perdidas | Push notifications via Firebase FCM |

---

## ✨ Funcionalidades Principais

### 👨‍⚕️ Painel do Médico (Flutter)
- **Dashboard inteligente** com KPIs em tempo real (pacientes, consultas, receita)
- **Gestão de consultas** completa: criar, confirmar, cancelar, concluir
- **Prontuário eletrônico** com anotações clínicas, sintomas, diagnóstico e prescrição digital
- **CRM de pacientes** com histórico de consultas e exames
- **Central de mensagens** integrada ao chat do paciente
- **Relatório financeiro** com gráficos por período
- **Receitas em PDF** enviadas automaticamente ao paciente via WhatsApp

### 👤 Área do Paciente (Flutter)
- Acompanhamento de consultas e status em tempo real
- Histórico de exames e laudos
- Chat com IA assistente (Isis) e médico
- Notificações push de confirmações e lembretes

### 🤖 Backend com IA (FastAPI + LangChain)
- **WhatsApp Webhook** — integração com WhatsApp Business Cloud API
- **RAG (Retrieval-Augmented Generation)** — IA que responde com base em documentos da clínica, evitando alucinações
- **Transcrição de áudio** — pacientes podem enviar áudios, a IA transcreve e processa
- **Moderação de conteúdo** — filtragem multimodal de textos e imagens
- **Agendador automático** — lembretes e follow-up de consultas
- **Prescrição digital** — geração de PDF e envio por WhatsApp

---

## 🏗️ Arquitetura

```
WhatsApp Business API
        ↓
Backend FastAPI (Python)
   ├── Webhook Handler
   ├── LangChain RAG Engine
   ├── Moderação de Conteúdo
   ├── PostgreSQL (banco de dados)
   └── Firebase FCM (push notifications)
        ↓
App Flutter (Mobile + Web)
   ├── Painel do Médico (/dashboard)
   ├── Área do Paciente (/client)
   └── Área Admin (/management-v1)
```

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| **Mobile / Web** | Flutter 3.x, Material 3, Riverpod, GoRouter |
| **Backend API** | Python 3.10, FastAPI, SQLAlchemy, Uvicorn |
| **Inteligência Artificial** | LangChain, RAG, Chroma Vector DB, Groq/Whisper |
| **Banco de Dados** | PostgreSQL (SQLite em dev local) |
| **Notificações Push** | Firebase Cloud Messaging (FCM) |
| **Integração WhatsApp** | WhatsApp Business Cloud API (Meta) |

---

## 🚀 Como Rodar

### Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x)
- Python 3.10+
- ngrok (ou similar) para expor o backend ao WhatsApp

### 1. Configurar o `.env` do Flutter

Edite o arquivo `frontend/assets/.env`:

```env
# Para Web/iOS/macOS (localhost)
API_URL=http://localhost:8000

# Para ngrok (recomendado para testes com WhatsApp)
# API_URL=https://seu-tunnel.ngrok-free.dev
# API_URL_WEB=https://seu-tunnel.ngrok-free.dev
# API_URL_MOBILE=https://seu-tunnel.ngrok-free.dev

# Para emulador Android
# API_URL=http://10.0.2.2:8000
```

### 2. Setup automático (recomendado)

```bash
# Na raiz do projeto
./bash/setup_project.sh
```

O script instala as dependências do Flutter (`flutter pub get`) e cria o ambiente virtual Python do backend.

### 3. Iniciar o Backend

```bash
./bash/start_server.sh
```

O backend estará disponível em `http://localhost:8000`  
Documentação interativa: `http://localhost:8000/docs`

### 4. Iniciar o Flutter

```bash
./bash/run_all.sh
```

Abre o app no Chrome **e** no macOS simultaneamente.

Ou manualmente:

```bash
cd frontend
flutter pub get
flutter run -d chrome      # Web
flutter run -d macos       # macOS nativo
```

---

## 🗂️ Estrutura do Projeto

```
/
├── frontend/              # App Flutter (Mobile + Web)
│   ├── lib/
│   │   ├── core/          # Theme, network, utils
│   │   ├── features/      # Módulos por funcionalidade
│   │   │   ├── auth/         # Login, registro, autenticação JWT
│   │   │   ├── dashboard/    # Painel principal do médico
│   │   │   ├── appointments/ # CRUD de consultas
│   │   │   ├── patients/     # CRM de pacientes
│   │   │   ├── chat/         # Chat IA + médico
│   │   │   ├── messages/     # Central de mensagens
│   │   │   ├── client/       # Área do paciente
│   │   │   ├── landing/      # Landing page (web)
│   │   │   └── admin/        # Painel administrativo
│   │   └── shared/        # Models, widgets compartilhados
│   └── assets/.env        # Configuração da API
│
├── backend/               # API FastAPI (Python)
│   ├── app/
│   │   ├── api/           # Endpoints REST
│   │   ├── models/        # Modelos SQLAlchemy
│   │   ├── services/      # Lógica de negócio + IA
│   │   ├── rag/           # Motor de IA com RAG
│   │   └── core/          # Config, scheduler
│   └── requirements.txt
│
├── bash/                  # Scripts de automação
│   ├── run_all.sh         # Inicia Flutter (Chrome + macOS)
│   ├── start_server.sh    # Inicia backend Python
│   └── setup_project.sh   # Setup inicial do projeto
│
└── docs/                  # Documentação do projeto
```

---

## 🔐 Credenciais de Teste

| Perfil | Usuário | Senha |
|:---|:---|:---|
| **Médico** | `marina.costa` | `senha123` |
| **Médico** | `dr.carlos` | `senha123` |
| **Admin** | `admin` | `admin123` |
| **Paciente** | Cadastre no app | — |

> **Paciente de teste WhatsApp:** Pedro Santiago · CPF: `123.456.789-00` · WhatsApp: `5511988888888`

---

## 🔌 API Endpoints Principais

| Método | Rota | Descrição |
|---|---|---|
| `POST` | `/api/auth/login` | Autenticação JWT |
| `GET` | `/api/dashboard/stats` | KPIs do dashboard |
| `GET` | `/api/appointments` | Lista de consultas |
| `POST` | `/api/appointments` | Criar consulta |
| `GET` | `/api/patients` | Lista de pacientes |
| `POST` | `/api/chat` | Chat com IA |
| `POST` | `/api/rag/query` | Consulta RAG |
| `POST` | `/webhook` | Webhook WhatsApp |
| `GET` | `/health` | Status da API |
| `GET` | `/docs` | Swagger UI |

---

## 🎨 Design System

O app segue os princípios de **Clean UI** e **Material 3** com uma paleta de azuis profissional:

| Token | Hex | Uso |
|---|---|---|
| Primary Blue Dark | `#001D39` | Títulos, AppBar, ícones ativos |
| Primary Blue | `#003D9B` | Botões primários, destaques |
| Primary Blue Light | `#DAE2FF` | Fundos de cards, badges |
| Secondary | `#4E8EA2` | Gradientes, detalhes |

Tipografia: **Manrope** (títulos) + **Inter** (corpo) via Google Fonts.

---

## 🧪 Qualidade de Código

```bash
# Análise estática
cd frontend && flutter analyze

# Testes
cd frontend && flutter test
```

---

## 📝 Documentação Adicional

- [`docs/README-OmniConnect.md`](docs/README-OmniConnect.md) — Visão geral detalhada do projeto
- [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) — Paleta de cores e componentes
- [`docs/dados_teste.md`](docs/dados_teste.md) — Dados de teste do sistema
- [`docs/Regras.md`](docs/Regras.md) — Regras de negócio e visão do produto
- [`frontend/lib/DOCUMENTACAO_FLUTTER.md`](frontend/lib/DOCUMENTACAO_FLUTTER.md) — Documentação técnica do Flutter

---

## 📄 Licença

MIT © 2026 — Desenvolvido como projeto de conclusão do Desafio Tech.
