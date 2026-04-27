import sys
import os

# Adiciona o diretório raiz ao PYTHONPATH para permitir a importação do módulo executor
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from executor.agent_system import AgentSystem

system = AgentSystem()

task = "Criar API FastAPI com endpoint webhook para WhatsApp"

response = system.execute(task)

print(response)