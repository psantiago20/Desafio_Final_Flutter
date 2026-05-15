#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "========================================"
echo "  Pitaya - Starting Development Environment"
echo "========================================"

start_service() {
    local name=$1
    local port=$2
    echo ""
    echo "Starting $name on port $port..."
    cd "$PROJECT_ROOT/$name"
    mvn spring-boot:run -DskipTests -q > "$PROJECT_ROOT/logs/$name.log" 2>&1 &
    echo "  PID: $!"
    cd "$PROJECT_ROOT"
}

mkdir -p logs

echo ""
echo "[1/4] Starting infrastructure services..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d \
    postgres redis rabbitmq

echo "  Waiting for infrastructure to be healthy..."
for container in postgres redis rabbitmq; do
    echo -n "    $container: "
    until docker compose exec "$container" true 2>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo " healthy"
done

echo ""
echo "[2/4] Starting discovery-service..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d \
    discovery-service config-service

echo "  Waiting for discovery-service to register..."
until curl -s http://localhost:8761/actuator/health | grep -q UP; do
    echo -n "."
    sleep 3
done
echo " healthy"

echo ""
echo "[3/4] Starting gateway-service..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d \
    gateway-service

until curl -s http://localhost:8080/actuator/health | grep -q UP; do
    echo -n "."
    sleep 2
done
echo "  Gateway healthy"

echo ""
echo "[4/4] Starting all microservices..."
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d \
    auth-service user-service post-service group-service \
    library-service mentorship-service gamification-service notification-service

echo ""
echo "========================================"
echo "  Development Environment is Starting"
echo "========================================"
echo ""
echo "  Gateway:     http://localhost:8080"
echo "  Discovery:   http://localhost:8761"
echo "  Config:      http://localhost:8888"
echo "  Auth:        http://localhost:8081"
echo "  User:        http://localhost:8082"
echo "  Post:        http://localhost:8083"
echo "  Group:       http://localhost:8084"
echo "  Library:     http://localhost:8085"
echo "  Mentorship:  http://localhost:8086"
echo "  Gamification: http://localhost:8087"
echo "  Notification: http://localhost:8088"
echo ""
echo "  RabbitMQ UI: http://localhost:15672 (pitaya/rabbit123)"
echo "  Prometheus:  http://localhost:9090"
echo "  Grafana:     http://localhost:3000 (admin/admin)"
echo ""
echo "  Logs: ./logs/"
echo ""

echo "Waiting for all services to register with Eureka..."
echo "  (This may take 1-2 minutes)"

timeout=120
elapsed=0
while [ $elapsed -lt $timeout ]; do
    count=$(curl -s http://localhost:8761/eureka/apps | grep -o '"status":"UP"' | wc -l)
    echo -ne "  Registered services: $count/11\r"
    if [ "$count" -ge 11 ]; then
        echo ""
        echo "  All services registered successfully!"
        break
    fi
    sleep 5
    elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $timeout ]; then
    echo ""
    echo "  Warning: Not all services registered within timeout."
    echo "  Check logs with: ./scripts/health-check.sh"
fi

echo ""
echo "Run './scripts/health-check.sh' to verify all services."
