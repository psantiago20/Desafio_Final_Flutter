.PHONY: build test run docker-build docker-up docker-down clean logs health help

SHELL := /bin/bash

help:
	@echo "Pitaya Social Network - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build        Build all services with Maven (skip tests)"
	@echo "  make test         Run all tests"
	@echo "  make run          Start Maven services locally (dev mode)"
	@echo "  make docker-build Build all Docker images"
	@echo "  make docker-up    Start full environment with Docker Compose"
	@echo "  make docker-down  Stop Docker Compose environment"
	@echo "  make clean        Clean all build artifacts"
	@echo "  make logs         Tail logs from all Docker services"
	@echo "  make health       Check health of all services"

build:
	mvn clean package -DskipTests -B -q

test:
	mvn clean verify -B -q

run:
	@echo "Starting infrastructure..."
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d postgres redis rabbitmq
	@echo "Starting services in background..."
	(mvn spring-boot:run -pl discovery-service -DskipTests -q > logs/discovery.log 2>&1 &)
	@echo "  discovery-service started"
	(sleep 15 && mvn spring-boot:run -pl config-service -DskipTests -q > logs/config.log 2>&1 &)
	@echo "  config-service started"
	(sleep 15 && mvn spring-boot:run -pl gateway-service -am -DskipTests -q > logs/gateway.log 2>&1 &)
	@echo "  gateway-service started"
	(mvn spring-boot:run -pl services/auth-service -am -DskipTests -q > logs/auth.log 2>&1 &)
	@echo "  auth-service started"
	(mvn spring-boot:run -pl services/user-service -am -DskipTests -q > logs/user.log 2>&1 &)
	@echo "  user-service started"
	(mvn spring-boot:run -pl services/post-service -am -DskipTests -q > logs/post.log 2>&1 &)
	@echo "  post-service started"
	(mvn spring-boot:run -pl services/group-service -am -DskipTests -q > logs/group.log 2>&1 &)
	@echo "  group-service started"
	(mvn spring-boot:run -pl services/library-service -am -DskipTests -q > logs/library.log 2>&1 &)
	@echo "  library-service started"
	(mvn spring-boot:run -pl services/mentorship-service -am -DskipTests -q > logs/mentorship.log 2>&1 &)
	@echo "  mentorship-service started"
	(mvn spring-boot:run -pl services/gamification-service -am -DskipTests -q > logs/gamification.log 2>&1 &)
	@echo "  gamification-service started"
	(mvn spring-boot:run -pl services/notification-service -am -DskipTests -q > logs/notification.log 2>&1 &)
	@echo "  notification-service started"
	@echo ""
	@echo "All services starting. Check logs/ for output."

docker-build:
	@echo "Building Docker images..."
	@for service in discovery-service config-service gateway-service \
		services/auth-service services/user-service services/post-service \
		services/group-service services/library-service services/mentorship-service \
		services/gamification-service services/notification-service; do \
		name=$$(basename $$service); \
		echo "  Building pitaya/$$name..."; \
		docker build -f $$service/Dockerfile -t pitaya/$$name:latest .; \
	done

docker-up:
	docker compose -f docker-compose.yml up -d

docker-down:
	docker compose -f docker-compose.yml down

docker-dev-up:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

docker-dev-down:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml down

clean:
	mvn clean -B -q
	@rm -rf logs/ backups/

logs:
	docker compose logs -f

health:
	@bash scripts/health-check.sh
