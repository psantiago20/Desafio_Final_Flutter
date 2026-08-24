import os

def load_agents(path="agents/skills-md"):
    agents = {}
    
    # Adicionado fallback pro caso de ser executado a partir de dentro da pasta executor/
    if not os.path.exists(path) and os.path.exists(os.path.join("..", path)):
        path = os.path.join("..", path)

    if not os.path.exists(path):
        print(f"Aviso: Diretório de skills não encontrado: {path}")
        return agents

    for file in os.listdir(path):
        if file.endswith(".md"):
            with open(os.path.join(path, file), "r", encoding="utf-8") as f:
                agents[file.replace(".md", "")] = f.read()

    return agents