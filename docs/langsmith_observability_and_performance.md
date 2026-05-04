# Observabilidade e Performance: LangSmith & Latência

Este documento estabelece as regras de orquestração para monitoramento via LangSmith e as diretrizes arquiteturais para manter a latência do sistema abaixo de 2 segundos, conforme o contrato `orchestrate-omniconnect.md`.

---

## 1. Regras de Mapeamento e Tags no LangSmith

Para evitar que testes locais (debug) sujem as métricas de produção e inflacionem a latência irreal (como picos de 382s), todas as invocações ao LangChain/LangGraph DEVEM incluir metadados de rastreio.

### 1.1 Configuração de Ambiente (Tags Obrigatórias)
Todo fluxo RAG ou Agent no código deve ter as seguintes tags aplicadas em suas invocações:
- `env:dev` ou `env:prod` (dependendo de onde o backend está rodando).
- `source:whatsapp` ou `source:web` (para saber a origem da requisição).

**Exemplo de código no FastAPI (`rag_service.py` / `agent_tools.py`):**
```python
# Ao invocar o chain, agent ou retriever:
response = chain.invoke(
    {"input": mensagem_usuario},
    config={
        "tags": ["env:dev", "source:whatsapp", "teste-local"],
        "metadata": {
            "user_id": paciente_id,
            "session_id": session_id
        }
    }
)
```

### 1.2 Uso do LangSmith para Investigação de Erros
- **Isolamento:** Vá na aba **Monitoring**, adicione um filtro `Tag = env:prod`. Isso mostrará a latência real dos usuários.
- **Drilldown de Erros:** Na aba **Tracing**, digite `error: true`. Ao abrir o trace em cascata (Waterfall), verifique o Stack Trace (aba direita) e a latência de cada passo.
- **Playground para Correção:** Se o erro foi alucinação do modelo ou quebra de JSON no *output parser*, use o botão "Open in Playground", corrija o *System Prompt*, valide com os mesmos dados, e traga a alteração para o código fonte.

---

## 2. Sistema para Redução de Latência (< 2s)

Mesmo sem contar os erros, uma latência de sucesso na faixa de 2.42s a 35.97s é inaceitável para uma experiência conversacional e viola o contrato do webhook da Meta (WhatsApp). 

Para forçar a latência para menos de 2s, a equipe (`backend-agent` e `rag-engineer`) DEVE implementar a seguinte arquitetura de otimização:

### 2.1 Desacoplamento do Webhook (Obrigatório para WhatsApp)
A Meta (WhatsApp) exige que o Webhook responda em **no máximo 2 a 3 segundos**, ou ela assume que a mensagem falhou, corta a conexão, e registra um erro na sua Dashboard da API Meta.
- **O Problema:** O endpoint `/webhook` do seu FastAPI atual provavelmente está esperando o RAG processar o banco de dados e a LLM gerar a resposta. Isso leva de 5 a 15 segundos em média.
- **A Solução (Prioridade 1):** Use `BackgroundTasks` (FastAPI) ou uma fila (ex: Celery). 
  1. O webhook recebe a mensagem do usuário.
  2. Envia a chamada do LangGraph para a *Background Task*.
  3. Imediatamente retorna `HTTP 200 OK` para a Meta (Latência < 50ms).
  4. Em paralelo, a tarefa termina e faz uma requisição POST diretamente para a API de envio de mensagens do WhatsApp Cloud API, mandando a resposta final para o celular da pessoa.

### 2.2 Otimização do RAG (Context e Embedding)
- **Tamanho do Contexto (Chunk Size):** Se você enviar muitos chunks do VectorStore (ex: `top_k = 10` com 1000 tokens cada), a LLM vai demorar muito para ler (aumentando o seu tempo de latência). **Reduza o `top_k` para 3 ou no máximo 5.**
- **Embeddings mais Rápidos:** Verifique se a API do embedding está lenta. Trocar para um embedding mais rápido (`text-embedding-3-small` da OpenAI ou um embedding local) tira dezenas a centenas de milissegundos da conta.

### 2.3 Cache Semântico
Perguntas idênticas ou muito similares (ex: "Vocês atendem Unimed?" vs "Aceita Unimed?") não devem gerar custos ou latência na LLM sempre.
- **Solução:** Implemente um Cache Semântico (usando o módulo `langchain-redis` ou `GPTCache`). Ao receber a pergunta, busque no cache se há similaridade alta com perguntas feitas nos últimos 30 minutos. Se sim, devolva a resposta instantaneamente (Latência ~50ms).

### 2.4 Roteamento Simplificado (LLMs menores)
Nem todo processamento exige os poderes complexos e lentos do melhor modelo disponível.
- **Solução:** Utilize um modelo ultrarrápido (ex: `Llama-3-8B` ou `GPT-4o-mini`) apenas para o papel de "Roteador" (avaliar a intenção do usuário: marcar consulta ou dúvida clínica). Apenas acione modelos mais "pesados" (e mais lentos) nas etapas da cadeia que requeiram muito raciocínio clínico.

### 2.5 Streaming de Tokens (Exclusivo Frontend Web/Flutter)
Embora o WhatsApp não suporte streaming (ver letras pipocando), o seu dashboard no Flutter na Web sim.
- **Solução:** No backend web, substitua o `.invoke()` pelo `.astream()`. Assim, o tempo do primeiro token (*Time To First Token*) cai drasticamente para cerca de 500ms, dando a percepção para o paciente de resposta instantânea.

---

## 3. Checklist e Plano de Ação
1. **Hoje:** Alterar o `app/main.py` e o webhook do Meta para utilizar `BackgroundTasks` do FastAPI.
2. **Amanhã:** Revisar o `app/services/rag_service.py` e injetar os Dicionários de *Tags* em todas as invocações `.invoke(..., config={"tags": ["env:dev"]})`.
3. **Próxima Semana:** Implementar Cache Semântico e experimentar diminuir o tamanho dos Chunks de RAG.
