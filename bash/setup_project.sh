#!/bin/bash

# --- Cores ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

echo -e "${BLUE}🚀 Iniciando o setup do projeto...${NC}"

# 1. Verificar Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter SDK não encontrado. Por favor, instale-o antes de continuar: https://docs.flutter.dev/get-started/install${NC}"
    exit 1
fi

# 2. Configurar .env no frontend
if [ ! -f frontend/assets/.env ]; then
    echo -e "${BLUE}📄 Criando frontend/assets/.env a partir do exemplo...${NC}"
    mkdir -p frontend/assets
    cp frontend/assets/.env.example frontend/assets/.env
    echo -e "${YELLOW}⚠️ Lembre-se de editar o arquivo frontend/assets/.env com a URL correta da API.${NC}"
else
    echo -e "${GREEN}✅ .env do frontend já existe.${NC}"
fi

# 3. Instalar dependências do Flutter
echo -e "${BLUE}📱 Instalando dependências do Flutter...${NC}"
cd frontend
flutter pub get
cd ..

# 4. Instalar dependências do backend (Python venv)
echo -e "${BLUE}🐍 Configurando ambiente Python do backend...${NC}"
BACKEND_DIR="$(pwd)/backend"

if [ ! -d "$BACKEND_DIR/.venv" ]; then
    echo -e "${YELLOW}⚠️  Ambiente virtual não encontrado. Criando...${NC}"
    python3 -m venv "$BACKEND_DIR/.venv"
    "$BACKEND_DIR/.venv/bin/python" -m pip install --upgrade pip
    "$BACKEND_DIR/.venv/bin/python" -m pip install -r "$BACKEND_DIR/requirements.txt"
else
    echo -e "${GREEN}✅ Ambiente virtual já existe.${NC}"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ PROJETO CONFIGURADO COM SUCESSO! ✨${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "\n${BLUE}Para iniciar o backend:${NC}"
echo -e "  ${YELLOW}./bash/start_server.sh${NC}"
echo -e "\n${BLUE}Para rodar o Flutter:${NC}"
echo -e "  ${YELLOW}./bash/run_all.sh${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
