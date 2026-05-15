#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================"
echo "  Pitaya - Stopping Development Environment"
echo "========================================"

echo ""
echo "Stopping Docker containers..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml down --remove-orphans

echo ""
echo "Stopping local Maven processes..."
pkill -f "spring-boot:run" 2>/dev/null || true

echo ""
echo "Cleaning up logs..."
rm -rf logs/

echo ""
echo "Development environment stopped."
echo "To remove volumes (WILL DELETE DATA), run:"
echo "  docker compose down -v"
