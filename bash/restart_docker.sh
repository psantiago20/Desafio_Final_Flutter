#!/bin/bash

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

echo "🚀 Reiniciando o Docker do projeto OmniConnect..."

# Para os containers e remove os volumes órfãos (opcional)
echo "🛑 Parando containers..."
docker-compose down

# Sobe os containers novamente
# --build garante que qualquer mudança no Dockerfile seja aplicada
echo "🏗️ Subindo containers..."
docker-compose up -d --build

echo "✅ Docker reiniciado com sucesso!"
echo "📊 Status dos containers:"
docker-compose ps
