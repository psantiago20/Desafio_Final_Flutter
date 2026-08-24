# OmniConnect – Gestão Inteligente de Serviços

OmniConnect é uma plataforma inteligente que conecta **clientes** e **prestadores de serviços** por meio do **WhatsApp**, **Inteligência Artificial (IA)** e **aplicações Flutter**, organizando todo o ciclo de vida do atendimento de forma estruturada, escalável e auditável.

Este projeto foi desenvolvido como solução completa para o **Desafio Tech – Gestão Inteligente de Serviços**.

---

## Visão Geral

Empresas de serviços enfrentam dois grandes problemas:
- Perda de informações em conversas informais no WhatsApp
- Falta de visibilidade e histórico estruturado dos atendimentos

O **OmniConnect** resolve isso ao centralizar o atendimento iniciado no WhatsApp, processar os dados via IA e sincronizar tudo em tempo real com aplicações Flutter.

---

## Objetivos

- Automatizar a triagem inicial via WhatsApp
- Organizar e centralizar dados de atendimento
- Prover visibilidade para clientes e fornecedores
- Reduzir fricção operacional
- Oferecer arquitetura moderna e escalável

---

## Arquitetura Geral

```text
Cliente (WhatsApp)
      ↓
WhatsApp Cloud API (Webhook)
      ↓
Backend (API REST)
      ↓
IA (LangChain + RAG)
      ↓
Banco de Dados
      ↓
Apps Flutter (Cliente e Fornecedor)
      ↓
Notificações Push (Firebase FCM)
```

---

## Stack Tecnológica

### Frontend
- Flutter (Mobile/Web)
- Material 3
- Riverpod
- Firebase Cloud Messaging (FCM)

### Backend
- Node.js ou FastAPI (Python)
- API REST
- Repository Pattern

### Inteligência Artificial
- LangChain
- RAG (Retrieval-Augmented Generation)
- Vector Database (Chroma / Pinecone / PGVector)
- Integração com LLM

### Infraestrutura
- PostgreSQL ou MongoDB
- Docker / Containers
- WhatsApp Business Cloud API

---

## Perfis de Acesso

### Cliente
- Visualiza status do serviço
- Acompanha histórico
- Recebe notificações
- Centraliza documentos

### Fornecedor
- Dashboard de serviços
- Controle de agenda
- Atualização de status
- Notificações em tempo real

---

## Estrutura de Documentação

```text
0-Setup-OmniConnect.md
1-Home-OmniConnect.md
2-Create-Appointment-OmniConnect.md
3-Settings-OmniConnect.md
4-API-OmniConnect.md
5-Notification-OmniConnect.md
6-AI-RAG-OmniConnect.md
7-End-to-End-Flow-OmniConnect.md
8-Client-App-OmniConnect.md
```

---

## Inteligência Artificial

A IA do OmniConnect atua como suporte operacional:
- Atendimento via WhatsApp
- Respostas baseadas em documentos (RAG)
- Evita alucinações
- Escala para atendimento humano quando necessário

---

## Notificações

- Push notifications via Firebase
- Novo serviço pendente
- Atualizações de status
- Lembretes

---

## Qualidade e Robustez

- Tratamento de erros e exceções
- Estados de loading, erro e vazio
- Fallback para repositórios mock
- Preparado para mensagens de áudio e imagem

---

## Cronograma (4 semanas)

- Semana 1: Setup, API, WhatsApp, Flutter base
- Semana 2: IA, LangChain e RAG
- Semana 3: Apps Flutter + Firebase
- Semana 4: Testes, documentação e pitch

---

## Status

✔ Escopo completo
✘ Arquitetura validada
✘ Pronto para execução e avaliação

Status: Feito ✔ | Não implementado ✘

---

## Demonstração (Sugestão)

Fluxo de 10 minutos simulando:
1. Atendimento iniciado via WhatsApp
2. IA interpreta e cria serviço
3. Fornecedor recebe notificação
4. Serviço é concluído
5. Cliente acompanha tudo pelo app

---

## Licença

MIT © 2026
Projeto desenvolvido para fins educacionais e avaliação técnica.