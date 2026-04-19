# OmniConnect - Plano de Execução

## Visão Geral do Projeto

| Item | Detalhe |
|------|---------|
| **Nome** | OmniConnect - Gestão Inteligente de Serviços |
| **Stack Backend** | FastAPI (Python) |
| **Stack Frontend** | Flutter (Mobile) |
| **IA** | LangChain + RAG (NVIDIA Nim / Ollama fallback) |
| **Banco** | PostgreSQL |
| **Duração** | 4 semanas |

---

## Estrutura de Pastas do Projeto

```
Desafio_final/
├── backend/              # FastAPI
│   ├── app/
│   │   ├── api/          # Endpoints
│   │   ├── core/         # Configurações
│   │   ├── db/           # Banco de dados
│   │   ├── models/       # SQLAlchemy models
│   │   ├── schemas/      # Pydantic schemas
│   │   ├── services/     # Lógica de negócio
│   │   └── rag/          # LangChain + RAG
│   ├── tests/
│   └── requirements.txt
│
├── frontend/             # Flutter
│   ├── lib/
│   │   ├── app/
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── home/
│   │   │   ├── appointments/
│   │   │   ├── patients/
│   │   │   ├── messages/
│   │   │   ├── finance/
│   │   │   └── dashboard/
│   │   └── shared/
│   └── pubspec.yaml
│
├── docs/                 # Documentação
│   ├── api/
│   ├── arquitetura/
│   └── scripts/
│
└── docker-compose.yml    # Orquestração
```

---

## Cronograma Semanal

### Semana 1: Setup, Backend & WhatsApp

| Dia | Tarefa |
|-----|---------|
| 1-2 | Configurar ambiente Docker, PostgreSQL, FastAPI base |
| 3-4 | Criar models (User, Patient, Appointment, Message, Service) |
| 5 | API REST completa (CRUD) |
| 6-7 | Integração WhatsApp Webhook (simulação/sandbox) |

### Semana 2: IA, LangChain e RAG

| Dia | Tarefa |
|-----|---------|
| 1-2 | Configurar LangChain + Vector Store (Chroma/PGVector) |
| 3-4 | Implementar RAG com documentos mock |
| 5-6 | Integração LLM (NVIDIA Nim → Ollama fallback) |
| 7 | Endpoint de chat IA |

### Semana 3: Flutter + Firebase

| Dia | Tarefa |
|-----|---------|
| 1-2 | Setup Flutter + Firebase (FCM) |
| 3-4 | UI - Login/Auth + Home Dashboard |
| 5-6 | UI - Agenda + Appointments |
| 7 | UI - Mensagens + Chat IA |

### Semana 4: Testes, Documentação e Integração

| Dia | Tarefa |
|-----|---------|
| 1-2 | Integração Flutter ↔ Backend |
| 3-4 | Testes E2E + Correções |
| 5 | Documentação API + README |
| 6-7 | Pitch/Demonstração |

---

## Módulos do Sistema

| Módulo | Descrição |
|--------|-----------|
| **Atendimento** | Chatbot WhatsApp + IA + Triagem automática |
| **Agenda** | Calendário, horários, confirmação, tipos de consulta |
| **Pacientes** | CRM médico, histórico, documentos, tags |
| **Comunicação** | Central de mensagens, WhatsApp, templates |
| **Financeiro** | Receitas, relatórios, convênio vs particular |
| **Estoque** | Controle de materiais e alertas |
| **Dashboard** | KPIs, gráficos, insights IA |

---

## APIs Principais a Implementar

```
POST   /api/auth/login
POST   /api/auth/register
GET    /api/patients
POST   /api/patients
GET    /api/appointments
POST   /api/appointments
PUT    /api/appointments/{id}/status
GET    /api/messages
POST   /api/messages
POST   /api/chat/ia          # Chat com RAG
GET    /api/dashboard/stats
POST   /api/webhooks/whatsapp
GET    /api/finance/reports
```

---

## Considerações Técnicas

1. **WhatsApp**: Usar sandbox WA enquanto não tiver credenciais oficiais
2. **Firebase**: Criar projeto e configurar FCM na Semana 3
3. **RAG**: Criar ~10 documentos mock (políticas, FAQs, procedimentos)
4. **LLM**: NVIDIA Nim como principal, detectar falha e usar Ollama

---

## Pré-requisitos do Ambiente

- Python 3.10+
- Docker + Docker Compose
- Node.js 18+ (para Flutter se necessário)
- Flutter SDK 3.x
- Ollama (local) ou API NVIDIA Nim

---

## Status do Projeto

- [x] Plano de execução criado
- [ ] Backend FastAPI configurado
- [ ] Banco de dados PostgreSQL
- [ ] Models e schemas
- [ ] APIs REST
- [ ] WhatsApp Webhook
- [ ] LangChain + RAG
- [ ] Integração LLM
- [ ] Flutter + Firebase
- [ ] Testes E2E
- [ ] Documentação