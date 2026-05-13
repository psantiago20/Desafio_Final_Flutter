#!/bin/bash

# Navega para a pasta do frontend
cd frontend

echo "🚀 Iniciando Flutter no Chrome e no macOS simultaneamente..."

# Inicia no Chrome em background
flutter run -d chrome &

# Inicia no macOS
flutter run -d macos

# Aguarda os processos finalizarem
wait
