#!/bin/bash

# --- Cores ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

echo -e "${BLUE}🚀 Iniciando o setup completo do OmniConnect...${NC}"

# 1. Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️ Docker não encontrado.${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Deseja tentar instalar o Docker via Homebrew? (y/n)"
        read -r install_docker
        if [ "$install_docker" = "y" ]; then
            if ! command -v brew &> /dev/null; then
                echo -e "${RED}Homebrew não encontrado. Instale o Docker manualmente: https://www.docker.com/products/docker-desktop${NC}"
                exit 1
            fi
            brew install --cask docker
            echo -e "${GREEN}Docker instalado! Abra o Docker Desktop e rode este script novamente.${NC}"
            exit 0
        fi
    else
        echo -e "${RED}Por favor, instale o Docker (https://docs.docker.com/get-docker/) e tente novamente.${NC}"
        exit 1
    fi
fi

# Verificar se o Docker Daemon está rodando
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ O Docker não está rodando. Por favor, inicie o Docker Desktop e tente novamente.${NC}"
    exit 1
fi

# 2. Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter SDK não encontrado. Por favor, instale-o antes de continuar: https://docs.flutter.dev/get-started/install${NC}"
    exit 1
fi

# 3. Configurar .env na raiz
if [ ! -f .env ]; then
    echo -e "${BLUE}📄 Criando .env na raiz a partir do .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠️ Lembre-se de editar o arquivo .env e adicionar sua NVIDIA_API_KEY se for usar IA Vision.${NC}"
else
    echo -e "${GREEN}✅ .env da raiz já existe.${NC}"
fi

# 4. Configurar .env no frontend
if [ ! -f frontend/assets/.env ]; then
    echo -e "${BLUE}📄 Criando frontend/assets/.env a partir do exemplo...${NC}"
    mkdir -p frontend/assets
    cp frontend/assets/.env.example frontend/assets/.env
else
    echo -e "${GREEN}✅ .env do frontend já existe.${NC}"
fi

# 5. Subir Docker
echo -e "${BLUE}🐳 Subindo containers Docker (isso pode demorar na primeira vez)...${NC}"
docker compose up -d --build

# 6. Aguardar Banco de Dados estar saudável
echo -ne "${BLUE}⏳ Aguardando o banco de dados estar pronto...${NC}"
for i in {1..30}; do
    STATUS=$(docker inspect -f {{.State.Health.Status}} omniconnect-db 2>/dev/null)
    if [ "$STATUS" == "healthy" ]; then
        echo -e "\n${GREEN}✅ Banco de dados pronto!${NC}"
        break
    fi
    echo -n "."
    sleep 2
    if [ $i -eq 30 ]; then
        echo -e "\n${RED}❌ Timeout aguardando o banco de dados. Verifique os logs com 'docker compose logs postgres'${NC}"
        exit 1
    fi
done

# 7. Configurar Banco de Dados
echo -e "\n${BLUE}🗄️ Configurando banco de dados...${NC}"

# Pergunta se o usuário quer resetar o banco
echo -e "${YELLOW}Deseja realizar uma instalação LIMPA do banco de dados?${NC}"
echo -e "⚠️ Isso apagará todas as tabelas e dados existentes. (y/N)"
read -t 10 -r reset_db || reset_db="n"

if [[ "$reset_db" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🧹 Resetando banco de dados (Clean Install)...${NC}"
    docker compose exec backend bash -c "PYTHONPATH=. python scripts/reset_db.py"
else
    echo -e "${BLUE}🔄 Verificando/Atualizando tabelas existentes...${NC}"
    docker compose exec backend bash -c "PYTHONPATH=. python scripts/create_tables.py"
fi

echo -e "${BLUE}🌱 Injetando dados de teste (Seeds)...${NC}"
docker compose exec backend bash -c "PYTHONPATH=. python scripts/seed_test_users.py"


# 8. Instalar dependências do Flutter
echo -e "${BLUE}📱 Instalando dependências do Flutter...${NC}"
cd frontend
flutter pub get
cd ..

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ PROJETO CONFIGURADO COM SUCESSO! ✨${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${BLUE}Para rodar o aplicativo agora, use:${NC}"
echo -e "  ${YELLOW}./run_all.sh${NC}"
echo -e "\n${BLUE}Credenciais de teste:${NC}"
echo "  - Médico: dr.carlos / senha123"
echo "  - Admin: admin / admin123"
echo "  - Paciente: joao.silva / senha123"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
