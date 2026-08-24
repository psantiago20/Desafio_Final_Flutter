from langchain_openai import ChatOpenAI
from langchain_core.messages import SystemMessage, HumanMessage

llm = ChatOpenAI(temperature=0.1, model="gpt-4o-mini")

def run_agent(agent_name, agent_prompt, task):
    system_text = f"Você é o agente: {agent_name}\n\nInstruções:\n{agent_prompt}"
    human_text = f"Tarefa: {task}\n\nResponda seguindo estritamente as diretrizes da sua Skill fornecida nas instruções de sistema."

    messages = [
        SystemMessage(content=system_text),
        HumanMessage(content=human_text)
    ]

    response = llm.invoke(messages)

    return response.content