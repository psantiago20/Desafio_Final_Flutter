#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================"
echo "  Pitaya - Building All Services"
echo "========================================"

echo ""
echo "[1/5] Building project with Maven..."
mvn clean package -DskipTests -B -q

echo ""
echo "[2/5] Building Docker images..."
SERVICES=(
    "discovery-service"
    "config-service"
    "gateway-service"
    "services/auth-service"
    "services/user-service"
    "services/post-service"
    "services/group-service"
    "services/library-service"
    "services/mentorship-service"
    "services/gamification-service"
    "services/notification-service"
)

for service in "${SERVICES[@]}"; do
    name=$(basename "$service")
    echo "  -> Building pitaya/$name..."
    docker build \
        -f "$service/Dockerfile" \
        -t "pitaya/$name:latest" \
        -t "pitaya/$name:$(date +%Y%m%d-%H%M%S)" \
        .
done

echo ""
echo "[3/5] Build summary:"
echo "  Maven:     $(find . -name '*.jar' -path '*/target/*' | wc -l) artifacts"
echo "  Docker:    $(docker images 'pitaya/*' --format '{{.Repository}}:{{.Tag}}' | wc -l) images"

echo ""
echo "[4/5] Image sizes:"
docker images 'pitaya/*' --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'

echo ""
echo "[5/5] All services built successfully."
