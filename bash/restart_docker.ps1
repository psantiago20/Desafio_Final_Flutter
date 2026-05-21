Write-Host "🚀 Reiniciando o Docker do projeto OmniConnect..." -ForegroundColor Cyan

# Para os containers e remove os volumes para aplicar as novas colunas do banco
Write-Host "🛑 Parando containers e limpando volumes..." -ForegroundColor Yellow
docker compose down -v

# Sobe os containers novamente
# --build garante que qualquer mudança no Dockerfile seja aplicada
Write-Host "🏗️ Subindo containers..." -ForegroundColor Cyan
docker compose up -d --build

# Aguarda o banco estar pronto
Write-Host "⏳ Aguardando o banco de dados estar pronto..." -ForegroundColor Cyan -NoNewline
for ($i = 1; $i -le 30; $i++) {
    $Status = (docker inspect -f '{{.State.Health.Status}}' omniconnect-db 2>$null)
    if ($Status -eq "healthy") {
        Write-Host ""
        Write-Host "✅ Banco de dados pronto!" -ForegroundColor Green
        break
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
    if ($i -eq 30) {
        Write-Host ""
        Write-Host "❌ Timeout aguardando o banco de dados. Verifique os logs com 'docker compose logs postgres'" -ForegroundColor Red
        exit 1
    }
}

# Recria as tabelas e roda o seed principal
Write-Host "`n🗄️ Configurando banco de dados..." -ForegroundColor Cyan
docker compose exec -T backend bash -c 'PYTHONPATH=. python scripts/create_tables.py'
docker compose exec -T backend bash -c 'PYTHONPATH=. python scripts/seed_test_users.py'

Write-Host "✅ Docker reiniciado e banco populado com sucesso!" -ForegroundColor Green
Write-Host "📊 Status dos containers:" -ForegroundColor Cyan
docker compose ps
