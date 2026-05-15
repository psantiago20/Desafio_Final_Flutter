# Docker Compose Guide

## 1. Objective

Guide for deploying the Pitaya platform using Docker and Docker Compose, including environment setup, service orchestration, and production considerations.

## 2. Prerequisites

- Docker 24+
- Docker Compose 2.20+
- Git
- 8GB+ RAM available
- 20GB+ free disk space

## 3. Project Structure

```
backend/
├── docker-compose.yml
├── docker/
│   ├── postgres/
│   │   └── init.sh
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── grafana/
│   │   └── dashboards/
│   └── rabbitmq/
│       └── definitions.json
├── .env
├── gateway-service/
├── discovery-service/
├── config-service/
├── shared/
└── services/
    ├── auth-service/
    ├── user-service/
    ├── post-service/
    ├── group-service/
    ├── library-service/
    ├── mentorship-service/
    ├── gamification-service/
    └── notification-service/
```

## 4. Environment Variables

Create a `.env` file:

```bash
# Database
POSTGRES_USER=pitaya
POSTGRES_PASSWORD=pitaya_secure_password_2026
POSTGRES_DB=pitaya

# Redis
REDIS_PASSWORD=redis_secure_password

# RabbitMQ
RABBITMQ_USER=pitaya
RABBITMQ_PASS=rabbit_secure_password

# JWT
JWT_PRIVATE_KEY_BASE64=<base64-encoded-private-key>
JWT_PUBLIC_KEY_BASE64=<base64-encoded-public-key>

# Spring Profiles
SPRING_PROFILES_ACTIVE=prod

# Service Ports
GATEWAY_PORT=8080
AUTH_SERVICE_PORT=8081
USER_SERVICE_PORT=8082
POST_SERVICE_PORT=8083
GROUP_SERVICE_PORT=8084
LIBRARY_SERVICE_PORT=8085
MENTORSHIP_SERVICE_PORT=8086
GAMIFICATION_SERVICE_PORT=8087
NOTIFICATION_SERVICE_PORT=8088

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
GRAFANA_ADMIN_PASSWORD=grafana_admin

# Logging
LOG_LEVEL=INFO
```

## 5. Build Commands

```bash
# Build all services
cd backend
mvn clean package -DskipTests

# Build Docker images
docker-compose build

# Or build specific service
docker-compose build auth-service

# Pull infrastructure images
docker-compose pull postgres redis rabbitmq prometheus grafana
```

## 6. Startup Commands

```bash
# Start all services
docker-compose up -d

# Start with build
docker-compose up -d --build

# Start specific services
docker-compose up -d postgres redis rabbitmq
docker-compose up -d discovery-service
docker-compose up -d config-service
docker-compose up -d gateway-service

# Start services progressively
docker-compose up -d postgres redis rabbitmq
sleep 10
docker-compose up -d discovery-service
sleep 15
docker-compose up -d config-service
sleep 10
docker-compose up -d gateway-service auth-service user-service
sleep 10
docker-compose up -d post-service group-service library-service
sleep 10
docker-compose up -d mentorship-service gamification-service notification-service
```

## 7. Startup Order

```
1. postgres, redis, rabbitmq     (infrastructure)
2. discovery-service              (Eureka)
3. config-service                 (Spring Config)
4. gateway-service                (API Gateway)
5. auth-service, user-service     (core services)
6. post-service, group-service    (content services)
7. library-service, mentorship    (specialized services)
8. gamification, notification     (support services)
9. prometheus, grafana            (monitoring)
```

## 8. Health Checks

```bash
# Check all services
docker-compose ps

# Check specific service
docker-compose ps auth-service

# Service health endpoints
curl http://localhost:8761/actuator/health  # Discovery
curl http://localhost:8080/actuator/health  # Gateway
curl http://localhost:8081/actuator/health  # Auth
```

## 9. Logging

```bash
# Follow all logs
docker-compose logs -f

# Follow specific service
docker-compose logs -f auth-service

# Last N lines
docker-compose logs --tail=100 auth-service

# With timestamps
docker-compose logs -t auth-service

# Save logs to file
docker-compose logs -f > pitaya.log
```

## 10. Scaling

```bash
# Scale a service horizontally
docker-compose up -d --scale auth-service=3
docker-compose up -d --scale post-service=2

# Note: Gateway and Eureka handle load balancing automatically
```

## 11. Maintenance

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Restart a service
docker-compose restart auth-service

# Update a service
docker-compose pull auth-service
docker-compose up -d --build auth-service

# Clean unused resources
docker system prune -f
docker volume prune -f
```

## 12. Monitoring

```bash
# Prometheus metrics
open http://localhost:9090

# Grafana dashboards
open http://localhost:3000
# Default: admin / grafana_admin

# RabbitMQ management
open http://localhost:15672
# Default: pitaya / rabbit_secure_password
```

## 13. Backup & Restore

```bash
# Backup databases
docker exec pitaya-postgres pg_dump -U pitaya auth_db > backup_auth.sql
docker exec pitaya-postgres pg_dump -U pitaya user_db > backup_user.sql

# Restore database
cat backup_auth.sql | docker exec -i pitaya-postgres psql -U pitaya -d auth_db
```

## 14. Troubleshooting

| Problem | Solution |
|---------|----------|
| Service fails to start | Check logs: `docker-compose logs <service>` |
| Database connection error | Ensure postgres is healthy: `docker-compose ps` |
| Eureka registration fails | Check discovery-service health first |
| RabbitMQ connection refused | Ensure rabbitmq is healthy with management UI |
| Port conflict | Change port in .env or docker-compose.yml |
| Out of memory | Increase Docker memory or reduce service scale |
