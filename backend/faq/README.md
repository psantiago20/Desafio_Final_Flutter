# 📁 FAQ — Base de Conhecimento do RAG

Este diretório contém os documentos de FAQ que alimentam o sistema RAG (Retrieval-Augmented Generation) do OmniConnect.

## Estrutura

```
faq/
├── _global/          # FAQ compartilhada entre TODOS os médicos
│   ├── preparos_exames.md
│   ├── convenios_aceitos.md
│   ├── politica_cancelamento.md
│   ├── como_agendar.md
│   └── duvidas_frequentes.md
│
├── doctor_1/         # FAQ específica do médico com ID 1
│   ├── horarios.md
│   ├── especialidades.md
│   └── localizacao.md
│
├── doctor_2/         # FAQ específica do médico com ID 2
│   └── ...
│
└── README.md         # Este arquivo
```

## Como Funciona

1. **Pasta `_global/`**: Documentos que se aplicam a todos os médicos (preparos de exames, política de cancelamento, etc.)
2. **Pasta `doctor_{id}/`**: Documentos específicos de cada médico (horários, especialidades, localização)
3. Quando um paciente faz uma pergunta via WhatsApp, o RAG busca tanto na pasta `_global/` quanto na pasta do médico correspondente

## Como Adicionar Novos Documentos

1. Crie um arquivo `.md` ou `.txt` na pasta do médico ou em `_global/`
2. Escreva o conteúdo em formato natural (não precisa ser técnico)
3. Execute a re-indexação via API: `POST /api/rag/ingest/{doctor_id}` ou `POST /api/rag/ingest/all`

## Dicas para Escrever FAQs

- Use **perguntas e respostas** claras
- Inclua **variações** de como o paciente pode perguntar
- Mantenha as respostas **concisas** (1-3 parágrafos)
- Use **markdown** para estruturar (títulos, listas, negrito)

## Formatos Suportados

- `.md` (Markdown) — Recomendado
- `.txt` (Texto puro)
