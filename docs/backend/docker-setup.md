# Docker Setup

## 1. Objective

Document the complete Docker infrastructure for the Pitaya platform, including Dockerfiles, Docker Compose configuration, and containerization best practices.

## 2. Docker Compose Structure

```yaml
version: '3.8'

services:
  # Infrastructure
  postgres:
    image: postgres:16-alpine
    container_name: pitaya-postgres
    environment:
      POSTGRES_USER: pitaya
      POSTGRES_PASSWORD: pitaya123
      POSTGRES_MULTIPLE_DATABASES: auth_db,user_db,post_db,group_db,library_db,mentorship_db,gamification_db,notification_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./docker/postgres/init.sh:/docker-entrypoint-initdb.d/init.sh
    networks:
      - pitaya-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pitaya"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: pitaya-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - pitaya-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  rabbitmq:
    image: rabbitmq:3.13-management-alpine
    container_name: pitaya-rabbitmq
    ports:
      - "5672:5672"  # AMQP
      - "15672:15672"  # Management UI
    environment:
      RABBITMQ_DEFAULT_USER: pitaya
      RABBITMQ_DEFAULT_PASS: pitaya123
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - pitaya-network
    healthcheck:
      test: ["CMD", "rabbitmqctl", "status"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Platform Services
  discovery-service:
    build:
      context: ./discovery-service
      dockerfile: Dockerfile
    container_name: pitaya-discovery
    ports:
      - "8761:8761"
    networks:
      - pitaya-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8761/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  config-service:
    build:
      context: ./config-service
      dockerfile: Dockerfile
    container_name: pitaya-config
    ports:
      - "8888:8888"
    depends_on:
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  gateway-service:
    build:
      context: ./gateway-service
      dockerfile: Dockerfile
    container_name: pitaya-gateway
    ports:
      - "8080:8080"
    depends_on:
      discovery-service:
        condition: service_healthy
      config-service:
        condition: service_started
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  # Microservices
  auth-service:
    build:
      context: ./services/auth-service
      dockerfile: Dockerfile
    container_name: pitaya-auth
    ports:
      - "8081:8081"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  user-service:
    build:
      context: ./services/user-service
      dockerfile: Dockerfile
    container_name: pitaya-user
    ports:
      - "8082:8082"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  post-service:
    build:
      context: ./services/post-service
      dockerfile: Dockerfile
    container_name: pitaya-post
    ports:
      - "8083:8083"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  group-service:
    build:
      context: ./services/group-service
      dockerfile: Dockerfile
    container_name: pitaya-group
    ports:
      - "8084:8084"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  library-service:
    build:
      context: ./services/library-service
      dockerfile: Dockerfile
    container_name: pitaya-library
    ports:
      - "8085:8085"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  mentorship-service:
    build:
      context: ./services/mentorship-service
      dockerfile: Dockerfile
    container_name: pitaya-mentorship
    ports:
      - "8086:8086"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  gamification-service:
    build:
      context: ./services/gamification-service
      dockerfile: Dockerfile
    container_name: pitaya-gamification
    ports:
      - "8087:8087"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  notification-service:
    build:
      context: ./services/notification-service
      dockerfile: Dockerfile
    container_name: pitaya-notification
    ports:
      - "8088:8088"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
      discovery-service:
        condition: service_healthy
    networks:
      - pitaya-network
    environment:
      - SPRING_PROFILES_ACTIVE=docker

  monitoring:
    image: prom/prometheus:latest
    container_name: pitaya-prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./docker/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - pitaya-network

  grafana:
    image: grafana/grafana:latest
    container_name: pitaya-grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
      - ./docker/grafana/dashboards:/etc/grafana/provisioning/dashboards
    networks:
      - pitaya-network

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
  prometheus_data:
  grafana_data:

networks:
  pitaya-network:
    driver: bridge
```

## 3. Dockerfile (Java Service Template)

```dockerfile
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests -Pdocker

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
EXPOSE 8080

# Add non-root user
RUN addgroup -S pitaya && adduser -S pitaya -G pitaya
USER pitaya

# Copy JAR
COPY --from=builder /build/target/*.jar app.jar

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", \
    "-XX:+UseZGC", \
    "-XX:MaxRAMPercentage=75.0", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-jar", "app.jar"]
```

## 4. PostgreSQL Init Script

```bash
#!/bin/bash
# docker/postgres/init.sh

set -e

for db in auth_db user_db post_db group_db library_db mentorship_db gamification_db notification_db; do
    psql -U "$POSTGRES_USER" -c "CREATE DATABASE $db;"
    echo "Database $db created successfully"
done
```

## 5. Prometheus Configuration

```yaml
# docker/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'pitaya-services'
    metrics_path: '/actuator/prometheus'
    eureka_sd_configs:
      - server: http://discovery-service:8761/eureka
    relabel_configs:
      - source_labels: [__meta_eureka_app_name]
        target_label: application
```

## 6. Docker Compose Commands

```bash
# Start all services
docker-compose up -d

# Start specific services
docker-compose up -d postgres redis rabbitmq discovery-service config-service gateway-service

# View logs
docker-compose logs -f auth-service

# Rebuild and restart
docker-compose up -d --build auth-service

# Scale a service
docker-compose up -d --scale auth-service=3

# Stop all
docker-compose down

# Stop with volume removal
docker-compose down -v

# Check health
docker-compose ps
```

## 7. Container Architecture

```
                    ┌─────────────────────┐
                    │   Docker Network     │
                    │  pitaya-network      │
                    │   (bridge)          │
                    │                     │
                    │  ┌───────────────┐  │
                    │  │  Gateway:8080 │  │
                    │  └───────┬───────┘  │
                    │          │          │
                    │  ┌───────┴───────┐  │
                    │  │  Eureka:8761  │  │
                    │  │  Config:8888  │  │
                    │  └───────┬───────┘  │
                    │          │          │
                    │  ┌───────┴───────┐  │
                    │  │ Services:8081-│  │
                    │  │   8088        │  │
                    │  └───────┬───────┘  │
                    │          │          │
                    │  ┌───────┴───────┐  │
                    │  │ Postgres:5432 │  │
                    │  │ Redis:6379    │  │
                    │  │ Rabbit:5672   │  │
                    │  └───────────────┘  │
                    └─────────────────────┘
```

## 8. Environment Variables

All environment variables are documented in `docs/deployment/environment-variables.md`.

## 9. Best Practices

1. Use **multi-stage builds** to minimize image size
2. Run containers as **non-root user**
3. Implement **health checks** for all services
4. Use **specific version tags** (not `latest`)
5. Configure **log rotation** for containers
6. Use **Docker networks** for service isolation
7. Store secrets in **Docker secrets** or vault
8. Use **read-only root filesystem** where possible
9. Set **memory limits** for all containers
10. Use **init scripts** for database seeding
