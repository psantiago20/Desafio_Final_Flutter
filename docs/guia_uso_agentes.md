# 🤖 Guia Definitivo: Como Utilizar o Time de Agentes OmniConnect

Bem-vindo ao orquestrador multiagentes do **Projeto OmniConnect**. Este repositório não é apenas uma aplicação padrão, mas sim um ecossistema impulsionado por Inteligência Artificial onde "Especialistas" (Agentes) trabalham em conjunto para acelerar seu desenvolvimento.

Neste guia, você aprenderá como a arquitetura do orquestrador funciona e como tirar o melhor proveito desta equipe virtual.

---

## 🏛️ 1. Entendendo a Arquitetura do Orquestrador

O sistema foi desenhado para ser autônomo e modular. O fluxo de uma requisição segue este caminho:

1. **Entrada da Tarefa (`app/main.py`)**: Você define um problema ou objetivo (ex: *"Criar API FastAPI com endpoint webhook para WhatsApp"*).
2. **Carregamento Automático (`agent_loader.py`)**: O sistema inicializa e lê todos os arquivos `.md` dentro da pasta `agents/skills-md/`. Cada arquivo é uma "Skill" ou "Persona" diferente (Backend, Frontend, DevOps, etc.).
3. **O Roteador Inteligente (`orchestrator_engine.py`)**: Atuando como o "Gerente" do sistema, o roteador consome as regras principais localizadas em `agents/orchestrate-omniconnect.md`. Ele usa essas diretrizes junto com um LLM (ex: `gpt-4o-mini`) para analisar a sua tarefa, comparar com os operários disponíveis e delegar o trabalho para o especialista adequado.
4. **Execução Especializada (`agent_executor.py`)**: O agente escolhido assume o controle. O modelo de IA recebe as diretrizes rígidas daquela Skill específica (o *System Prompt*) junto com a sua tarefa, garantindo uma resposta altamente técnica e focada na sua área de domínio.

---

## 🎯 2. Como Escrever Boas Tarefas (A Arte de Pedir)

Como o Orquestrador ("Router") é uma IA, a forma como você descreve a tarefa dita quem será chamado. 

**❌ Ruim (Muito vago):**
> *"Faça a tela de login."*
*(O roteador pode ficar confuso se isso é UI/UX, Flutter ou Backend).*

**✅ Bom (Contexto claro):**
> *"Preciso criar a tela de login no aplicativo mobile usando Flutter. Inclua os campos de email e senha e os métodos de validação no formulário."*
*(Fica claro que o `flutter-frontend-agent` deve ser acionado).*

**✅ Bom (Focado em RAG/IA):**
> *"Implemente a lógica de RAG (Retrieval-Augmented Generation) para processar o histórico de mensagens do WhatsApp e guardar no banco vetorial."*
*(Acionará perfeitamente o `rag-engineer`).*

---

## 👥 3. Conhecendo Seu Time (As Personas)

Seu time vive na pasta `agents/skills-md/`. Aqui estão alguns dos seus principais colegas:

* 🎨 **`ui-ux-designer-agent`**: Chame-o para concepção de fluxos, paletas de cores e experiência do usuário.
* 📱 **`flutter-frontend-agent`**: O desenvolvedor mobile. Sabe tudo sobre o app do Cliente e do Fornecedor.
* ⚙️ **`develop-fastapi-backend`**: Seu líder de API. Sabe estruturar endpoints, gerenciar webhooks do WhatsApp e lógica de negócios.
* 🧠 **`rag-engineer`**: O especialista em LangChain, Vetores e integração LLM. Ele cria o "cérebro" do bot.
* 🗄️ **`database-architect`**: Para delinear esquemas do MongoDB/PostgreSQL e modelagem de dados.
* 🧪 **`qa-test-engineer`** e 👮 **`code-review-agent`**: Seus revisores e criadores de testes unitários/integrados.

---

## 🔄 4. Iterando e Encadeando Tarefas (Pipelines Manuais)

Para tirar o **máximo proveito**, não peça para um agente fazer o software inteiro. Encadeie fluxos de trabalho trabalhando como um "Tech Lead":

**Exemplo de Fluxo ideal de Trabalho (Pipeline):**

1. **Passo 1 (Arquitetura):**
   * *Sua Tarefa:* *"Desenhe a modelagem de dados para armazenar as mensagens do WhatsApp do cliente."*
   * *Agente chamado:* `database-architect`.
2. **Passo 2 (Backend):**
   * Você pega a resposta do arquiteto e envia numa nova tarefa.
   * *Sua Tarefa:* *"Baseado neste modelo de dados [cole o código aqui], crie os endpoints de FastAPI para interagir com o Webhook da Cloud API."*
   * *Agente chamado:* `develop-fastapi-backend`.
3. **Passo 3 (Verificação):**
   * *Sua Tarefa:* *"Escreva os testes Pytest para essas rotas FastAPI [código aqui] focando nos edge cases."*
   * *Agente chamado:* `qa-test-engineer`.

*Dica: Você pode programar no próprio `main.py` um script que pega a resposta de um agente e automaticamente põe no input de outro.*

---

## ➕ 5. Como Contratar Novos Agentes (Escalabilidade)

Adicionar um novo talento ao seu time não exige nenhuma mudança no código em Python! 

1. Crie um novo arquivo markdown na pasta `agents/skills-md/`. 
   * *Exemplo: `marketing-copywriter-agent.md`*
2. Escreva as regras de como essa pessoa deve se comportar. Use imperativos ("Você é o redator sênior... Só responda com textos de venda...").
3. Pronto. Na próxima execução, o `agent_loader` registrará este novo agente no sistema e o *Orchestrator* saberá que ele existe, passando a rotear tarefas de marketing para ele.

---

## ⚠️ Checklist de Sobrevivência (Importante)

- [ ] **Variáveis de Ambiente:** Como seus agentes usam a OpenAI, certifique-se de definir a variável de ambiente `OPENAI_API_KEY` rodando no seu terminal ou num arquivo `.env`.
- [ ] **Instalação das Dependências:** Sempre mantenha as `langchain-core` e `langchain-openai` atualizadas em sua máquina.
- [ ] **Monitoramento de Custos:** Todo acionamento custará tokens. O Orquestrador (roteamento) usa o modelo mini (barato), mas fique atento a qual modelo seus agentes estão utilizando nas regras de negócio (idealmente *gpt-4o-mini* para rotinas gerais e *gpt-4o* para problemas muito complexos).

Divirta-se orquestrando seu time na criação do OmniConnect! 🚀