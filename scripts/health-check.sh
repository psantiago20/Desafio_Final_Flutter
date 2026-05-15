#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SERVICES=(
    "discovery-service:8761"
    "config-service:8888"
    "gateway-service:8080"
    "auth-service:8081"
    "user-service:8082"
    "post-service:8083"
    "group-service:8084"
    "library-service:8085"
    "mentorship-service:8086"
    "gamification-service:8087"
    "notification-service:8088"
)

INFRA=(
    "postgres:5432"
    "redis:6379"
    "rabbitmq:5672"
)

echo "========================================"
echo "  Pitaya - Health Check"
echo "  $(date)"
echo "========================================"

check_endpoint() {
    local name=$1
    local port=$2
    local url="http://localhost:${port}/actuator/health"

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null || echo "000")

    if [ "$response" = "200" ]; then
        local status
        status=$(curl -s "$url" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('status','UNKNOWN'))" 2>/dev/null || echo "UNKNOWN")
        if [ "$status" = "UP" ]; then
            echo -e "  ${GREEN}[UP]${NC}   $name -> $status"
        else
            echo -e "  ${YELLOW}[DEGRADED]${NC} $name -> $status"
        fi
    elif [ "$response" = "000" ]; then
        echo -e "  ${RED}[DOWN]${NC}  $name -> Connection refused"
    elif [ "$response" = "503" ]; then
        echo -e "  ${YELLOW}[BUSY]${NC}  $name -> Service unavailable"
    else
        echo -e "  ${RED}[ERR]${NC}   $name -> HTTP $response"
    fi
}

echo ""
echo "Infrastructure:"
for entry in "${INFRA[@]}"; do
    name="${entry%%:*}"
    port="${entry##*:}"
    if nc -z localhost "$port" 2>/dev/null; then
        echo -e "  ${GREEN}[UP]${NC}   $name (port $port)"
    else
        echo -e "  ${RED}[DOWN]${NC}  $name (port $port)"
    fi
done

echo ""
echo "Platform Services:"
for entry in "${SERVICES[@]}"; do
    name="${entry%%:*}"
    port="${entry##*:}"
    check_endpoint "$name" "$port"
done

echo ""
echo "Eureka Dashboard:"
EUREKA_URL="http://localhost:8761/eureka/apps"
eureka_response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$EUREKA_URL" 2>/dev/null || echo "000")
if [ "$eureka_response" = "200" ]; then
    echo -e "  ${GREEN}[UP]${NC}   Eureka Server"
    echo ""
    echo "Registered Applications:"
    curl -s "$EUREKA_URL" 2>/dev/null | python3 -c "
import sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.stdin)
root = tree.getroot()
apps = root.findall('.//application')
for app in apps:
    name = app.find('name').text if app.find('name') is not None else 'unknown'
    instances = app.findall('.//instance')
    up_count = sum(1 for i in instances if i.find('status') is not None and i.find('status').text == 'UP')
    total = len(instances)
    print(f'    {name}: {up_count}/{total} instances UP')
" 2>/dev/null || echo "    Could not parse Eureka response"
else
    echo -e "  ${RED}[DOWN]${NC}  Eureka Server"
fi

echo ""
echo "========================================"
echo "  Health check complete."
echo "========================================"
