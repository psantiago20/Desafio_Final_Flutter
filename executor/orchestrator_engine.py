from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage
import os

def load_orchestrator_prompt():
    # Tenta carregar o prompt nativo do orquestrador
    prompt_path = os.path.join(os.path.dirname(__file__), "..", "agents", "orchestrate-omniconnect.md")
    try:
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return "Você é o Orquestrador Central (Router) de uma equipe de desenvolvimento."

def select_agent(task, agents_registry):
    # Pega apenas os nomes dos agentes disponíveis (chaves do dicionário lido pelo loader)
    available_agents = list(agents_registry.keys())
    agents_list_str = "\n".join([f"- {agent}" for agent in available_agents])
    
    orchestrator_instructions = load_orchestrator_prompt()

    # Instruímos um modelo rápido e barato a atuar como roteador
    llm = ChatOpenAI(temperature=0, model="gpt-4o-mini")

    system_prompt = f"""
    {orchestrator_instructions}
    ---
    
    ESTADO ATUAL DO AMBIENTE:
    Seu trabalho agora é atuar como Roteador para a tarefa atual.
    
    Estes são os agentes dinâmicos disponíveis no registry:
    {agents_list_str}
    
    Regras Finais de Retorno:
    1. Analise o contexto da tarefa.
    2. Escolha APENAS UM agente da lista dinâmica acima.
    3. Responda APENAS com o nome exato do agente escolhido (ex: 'develop-fastapi-backend'), sem pontos finais, sem aspas, sem blocos de código e sem explicações.
    """

    messages = [
        SystemMessage(content=system_prompt),
        HumanMessage(content=f"Tarefa recebida do usuário: {task}")
    ]

    try:
        # Pede para o LLM escolher
        response = llm.invoke(messages)
        chosen_agent = response.content.strip()

        # Limpa possíveis formatações markdown residuais como `agente` ou ```agente```
        chosen_agent = chosen_agent.replace("`", "")

        # Valida se o agente inventou um nome ou se retornou um agente real
        if chosen_agent in available_agents:
            print(f"Orquestrador escolheu automaticamente: {chosen_agent}")
            return chosen_agent
        else:
            fallback = available_agents[0] if available_agents else "documentation-agent"
            print(f"Roteamento falhou (IA não escolheu um agente da lista). Usando fallback inicial: {fallback}")
            return fallback
            
    except Exception as e:
        print(f"Erro ao rotear: {e}")
        return "documentation-agent"