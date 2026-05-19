# --- Colors ---
$Green = "Green"
$Blue = "Cyan"
$Yellow = "Yellow"
$Red = "Red"

Write-Host "🚀 Iniciando o setup completo do OmniConnect..." -ForegroundColor $Blue

# 1. Verificar Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ Docker não encontrado." -ForegroundColor $Yellow
    Write-Host "Por favor, instale o Docker (https://docs.docker.com/get-docker/) e tente novamente." -ForegroundColor $Red
    exit 1
}

# Verificar se o Docker Daemon está rodando
$dockerInfo = docker info 2>$null
if ($null -eq $dockerInfo) {
    Write-Host "❌ O Docker não está rodando. Por favor, inicie o Docker Desktop e tente novamente." -ForegroundColor $Red
    exit 1
}

# 2. Verificar Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter SDK não encontrado. Por favor, instale-o antes de continuar: https://docs.flutter.dev/get-started/install" -ForegroundColor $Red
    exit 1
}

# 3. Configurar .env na raiz
if (!(Test-Path .env)) {
    Write-Host "📄 Criando .env na raiz a partir do .env.example..." -ForegroundColor $Blue
    Copy-Item .env.example .env
    Write-Host "⚠️ Lembre-se de editar o arquivo .env e adicionar sua NVIDIA_API_KEY se for usar IA Vision." -ForegroundColor $Yellow
} else {
    Write-Host "✅ .env da raiz já existe." -ForegroundColor $Green
}

# 4. Configurar .env no frontend
if (!(Test-Path frontend/assets/.env)) {
    Write-Host "📄 Criando frontend/assets/.env a partir do exemplo..." -ForegroundColor $Blue
    $null = New-Item -ItemType Directory -Path frontend/assets -Force
    Copy-Item frontend/assets/.env.example frontend/assets/.env
} else {
    Write-Host "✅ .env do frontend já existe." -ForegroundColor $Green
}

# 5. Subir Docker
Write-Host "🐳 Subindo containers Docker (isso pode demorar na primeira vez)..." -ForegroundColor $Blue
docker compose up -d --build

# 6. Aguardar Banco de Dados estar saudável
Write-Host "⏳ Aguardando o banco de dados estar pronto..." -ForegroundColor $Blue -NoNewline
for ($i = 1; $i -le 30; $i++) {
    $Status = (docker inspect -f '{{.State.Health.Status}}' omniconnect-db 2>$null)
    if ($Status -eq "healthy") {
        Write-Host ""
        Write-Host "✅ Banco de dados pronto!" -ForegroundColor $Green
        break
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 2
    if ($i -eq 30) {
        Write-Host ""
        Write-Host "❌ Timeout aguardando o banco de dados. Verifique os logs com 'docker compose logs postgres'" -ForegroundColor $Red
        exit 1
    }
}

# 7. Configurar Banco de Dados
Write-Host "`n🗄️ Configurando banco de dados..." -ForegroundColor $Blue

# Pergunta se o usuário quer resetar o banco
Write-Host "Deseja realizar uma instalação LIMPA do banco de dados?" -ForegroundColor $Yellow
Write-Host "⚠️ Isso apagará todas as tabelas e dados existentes. (y/N)" -ForegroundColor $Yellow

$reset_db = Read-Host "Opção [y/N]"
if ($null -eq $reset_db -or $reset_db -eq "") { $reset_db = "n" }

if ($reset_db -match "^[Yy]$") {
    Write-Host "🧹 Resetando banco de dados (Clean Install)..." -ForegroundColor $Blue
    docker compose exec -T backend bash -c 'PYTHONPATH=. python scripts/reset_db.py'
} else {
    Write-Host "🔄 Verificando/Atualizando tabelas existentes..." -ForegroundColor $Blue
    docker compose exec -T backend bash -c 'PYTHONPATH=. python scripts/create_tables.py'
}

Write-Host "🌱 Injetando dados de teste (Seeds)..." -ForegroundColor $Blue
docker compose exec -T backend bash -c 'PYTHONPATH=. python scripts/seed_test_users.py'

# 8. Instalar dependências do Flutter
Write-Host "📱 Instalando dependências do Flutter..." -ForegroundColor $Blue
Push-Location frontend
flutter pub get
Pop-Location

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Green
Write-Host "✨ PROJETO CONFIGURADO COM SUCESSO! ✨" -ForegroundColor $Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Green
Write-Host "`nPara rodar o aplicativo agora, use:" -ForegroundColor $Blue
Write-Host "  cd frontend; flutter run -d chrome" -ForegroundColor $Yellow
Write-Host "`nCredenciais de teste:" -ForegroundColor $Blue
Write-Host "  - Médico: marina.costa / senha123"
Write-Host "  - Admin: admin / admin123"
Write-Host "  - Paciente: (Cadastre-se na tela inicial)"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor $Green
