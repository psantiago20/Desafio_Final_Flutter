#!/bin/bash

# Script para iniciar o serviço do servidor (backend) OmniConnect
# Baseado na implementação funcional da branch serve-rag-imagem

# Cores para o output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}====================================================${NC}"
echo -e "${GREEN}      OmniConnect - Inicializando Servidor Backend${NC}"
echo -e "${BLUE}====================================================${NC}"

# Caminho base do projeto
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_ROOT/backend"

# 1. Parar serviços antigos (evita erro de porta já em uso)
echo -e "${YELLOW}🛑 Parando instâncias anteriores do uvicorn...${NC}"
pkill -f uvicorn || true
sleep 1

# 2. Verificar se o diretório backend existe
if [ ! -d "$BACKEND_DIR" ]; then
    echo -e "${RED}❌ Erro: Diretório 'backend' não encontrado em $PROJECT_ROOT.${NC}"
    exit 1
fi

# 3. Configurar Ambiente e Dependências
echo -e "\n${BLUE}[1/3] Preparando Ambiente...${NC}"
cd "$BACKEND_DIR"

if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}⚠️  Ambiente virtual não encontrado. Criando...${NC}"
    python3 -m venv .venv
    .venv/bin/python -m pip install --upgrade pip
    .venv/bin/python -m pip install -r requirements.txt
fi

# 4. Carregar Configurações (.env)
echo -e "\n${BLUE}[2/3] Carregando variáveis de ambiente...${NC}"
export PYTHONPATH="$BACKEND_DIR"

if [ -f "$PROJECT_ROOT/.env" ]; then
    echo "✓ Carregando .env da raiz."
    # Exportar variáveis do .env (ignorando comentários)
    export $(grep -v '^#' "$PROJECT_ROOT/.env" | xargs)
elif [ -f "$BACKEND_DIR/.env" ]; then
    echo "✓ Carregando .env do backend."
    export $(grep -v '^#' "$BACKEND_DIR/.env" | xargs)
fi

# 5. Iniciar o Servidor FastAPI
echo -e "\n${BLUE}[3/3] Iniciando Uvicorn...${NC}"
echo -e "${GREEN}🚀 Servidor rodando em: http://0.0.0.0:8000${NC}"
echo -e "${GREEN}📖 Documentação: http://localhost:8000/docs${NC}"
echo -e "${YELLOW}Dica: Pressione CTRL+C para encerrar.${NC}\n"

# Usamos o binário do python do venv diretamente para garantir que todas as dependências sejam encontradas
.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
