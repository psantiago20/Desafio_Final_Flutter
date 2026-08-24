from agent_loader import load_agents
from agent_executor import run_agent
from orchestrator_engine import select_agent

class AgentSystem:

    def __init__(self):
        self.agents = load_agents()

    def execute(self, task):
        agent_name = select_agent(task, self.agents)

        agent_prompt = self.agents.get(agent_name)

        if not agent_prompt:
            return f"Agente {agent_name} não encontrado"

        result = run_agent(agent_name, agent_prompt, task)

        return {
            "agent": agent_name,
            "result": result
        }