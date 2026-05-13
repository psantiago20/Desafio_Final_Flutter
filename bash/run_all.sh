#!/bin/bash

# Muda para o diretório raiz do projeto (um nível acima deste script)
cd "$(dirname "$0")/.."

# Navega para a pasta do frontend
cd frontend

# Instala pods se estiver no Mac (importante para o app macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detectado macOS. Verificando CocoaPods..."
    (cd macos && pod install)
fi

echo "🚀 Iniciando Flutter no Chrome e no macOS em terminais separados..."

# Abre uma nova janela do Terminal para o Chrome
osascript -e "tell app \"Terminal\" to do script \"cd '$PWD' && flutter run -d chrome\""

# Executa o macOS nesta janela atual para manter o controle interativo
flutter run -d macos
