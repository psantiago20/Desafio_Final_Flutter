#!/bin/bash

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

# Navega para a pasta do frontend
cd frontend

# Instala pods se estiver no Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detectado macOS. Verificando CocoaPods..."
    cd macos && pod install && cd ..
fi

# Inicia o Flutter no macOS e Chrome simultaneamente
echo "🚀 Iniciando Flutter no Chrome e no macOS simultaneamente..."

# Inicia no Chrome em background (ou foreground dependendo do OS)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Detectado Linux (Ubuntu). Iniciando Flutter apenas no Chrome..."
    flutter run -d chrome
else
    # Inicia no Chrome em background
    flutter run -d chrome &
    # Inicia no macOS
    flutter run -d macos
    # Aguarda os processos finalizarem
    wait
fi
