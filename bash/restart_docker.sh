#!/bin/bash

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

echo "🚀 Reiniciando o Docker do projeto OmniConnect..."

# Para os containers e remove os volumes para aplicar as novas colunas do banco
echo "🛑 Parando containers e limpando volumes..."
docker-compose down -v

# Sobe os containers novamente
# --build garante que qualquer mudança no Dockerfile seja aplicada
echo "🏗️ Subindo containers..."
docker compose up -d --build

# Aguarda o banco estar pronto
echo "⏳ Aguardando banco de dados..."
sleep 5

# Recria as tabelas e roda o seed principal
echo "🗄️ Configurando banco de dados..."
docker compose exec backend bash -c "PYTHONPATH=. python scripts/create_tables.py"
docker compose exec backend bash -c "PYTHONPATH=. python scripts/seed_test_users.py"

echo "✅ Docker reiniciado e banco populado com sucesso!"
echo "📊 Status dos containers:"
docker compose ps
