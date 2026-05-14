# ============================================================
# OmniConnect - Túnel SSH para o banco de dados do servidor
# Uso: .\tunnel_db.ps1
# Mantém o terminal aberto. Feche para encerrar o túnel.
# ============================================================

$SERVER_USER = "desafio11"
$SERVER_HOST = "desafio11.alphaedtech"
$LOCAL_PORT  = 5433
$REMOTE_PORT = 5432

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  OmniConnect - Túnel DB SSH" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Conectando em $SERVER_USER@$SERVER_HOST..." -ForegroundColor Yellow
Write-Host "Porta local : localhost:$LOCAL_PORT" -ForegroundColor Green
Write-Host "Porta remota: localhost:$REMOTE_PORT (servidor)" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione Ctrl+C para encerrar o túnel." -ForegroundColor Red
Write-Host ""

ssh -L "${LOCAL_PORT}:localhost:${REMOTE_PORT}" "${SERVER_USER}@${SERVER_HOST}" -N -o ServerAliveInterval=60 -o ServerAliveCountMax=3
