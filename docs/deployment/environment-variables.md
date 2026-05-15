# Environment Variables

## 1. Objective

Document all environment variables used across Pitaya services, organized by service, with descriptions, defaults, and security classifications.

## 2. Global Variables

| Variable | Description | Default | Required | Secret |
|----------|-------------|---------|----------|--------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `dev` | No | No |
| `TZ` | Container timezone | `UTC` | No | No |
| `JAVA_OPTS` | Additional JVM options | `-XX:+UseZGC` | No | No |

## 3. Database Variables

### PostgreSQL

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_HOST` | PostgreSQL hostname | `postgres` | Yes |
| `DB_PORT` | PostgreSQL port | `5432` | Yes |
| `DB_USER` | Database user | `pitaya` | Yes |
| `DB_PASSWORD` | Database password | — | Yes |
| `DB_NAME` | Database name | varies by service | Yes |

Per-Service Databases:

| Service | DB_NAME | Variable |
|---------|---------|----------|
| Auth Service | `auth_db` | `AUTH_DB_NAME` |
| User Service | `user_db` | `USER_DB_NAME` |
| Post Service | `post_db` | `POST_DB_NAME` |
| Group Service | `group_db` | `GROUP_DB_NAME` |
| Library Service | `library_db` | `LIBRARY_DB_NAME` |
| Mentorship Service | `mentorship_db` | `MENTORSHIP_DB_NAME` |
| Gamification Service | `gamification_db` | `GAMIFICATION_DB_NAME` |
| Notification Service | `notification_db` | `NOTIFICATION_DB_NAME` |

## 4. Redis Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `REDIS_HOST` | Redis hostname | `redis` | Yes |
| `REDIS_PORT` | Redis port | `6379` | Yes |
| `REDIS_PASSWORD` | Redis password | — | No |

## 5. RabbitMQ Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `RABBIT_HOST` | RabbitMQ hostname | `rabbitmq` | Yes |
| `RABBIT_PORT` | RabbitMQ AMQP port | `5672` | Yes |
| `RABBIT_USER` | RabbitMQ username | `pitaya` | Yes |
| `RABBIT_PASS` | RabbitMQ password | — | Yes |
| `RABBIT_MANAGEMENT_PORT` | Management UI port | `15672` | No |

## 6. JWT Variables

| Variable | Description | Required | Secret |
|----------|-------------|----------|--------|
| `JWT_PRIVATE_KEY` | RSA private key (PEM) | Yes | Yes |
| `JWT_PUBLIC_KEY` | RSA public key (PEM) | Yes | No |
| `JWT_ACCESS_EXPIRATION` | Access token TTL (ms) | No (default: 3600000) | No |
| `JWT_REFRESH_EXPIRATION` | Refresh token TTL (ms) | No (default: 86400000) | No |

## 7. Service Variables

### Auth Service

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTH_SERVER_PORT` | Server port | `8081` |
| `AUTH_DB_NAME` | Database name | `auth_db` |
| `LOGIN_ATTEMPT_MAX` | Max login attempts before lockout | `5` |
| `LOGIN_LOCKOUT_MINUTES` | Lockout duration | `15` |

### User Service

| Variable | Description | Default |
|----------|-------------|---------|
| `USER_SERVER_PORT` | Server port | `8082` |
| `USER_DB_NAME` | Database name | `user_db` |

### Post Service

| Variable | Description | Default |
|----------|-------------|---------|
| `POST_SERVER_PORT` | Server port | `8083` |
| `POST_DB_NAME` | Database name | `post_db` |
| `POST_MAX_LENGTH` | Maximum post length | `5000` |
| `TRENDING_WINDOW_HOURS` | Trending calculation window | `24` |

### Group Service

| Variable | Description | Default |
|----------|-------------|---------|
| `GROUP_SERVER_PORT` | Server port | `8084` |
| `GROUP_DB_NAME` | Database name | `group_db` |
| `GROUP_MAX_MEMBERS` | Maximum members per group | `500` |

### Library Service

| Variable | Description | Default |
|----------|-------------|---------|
| `LIBRARY_SERVER_PORT` | Server port | `8085` |
| `LIBRARY_DB_NAME` | Database name | `library_db` |
| `FILE_STORAGE_PATH` | File storage directory | `/data/files` |
| `MAX_FILE_SIZE` | Max upload size (bytes) | `52428800` (50MB) |

### Mentorship Service

| Variable | Description | Default |
|----------|-------------|---------|
| `MENTORSHIP_SERVER_PORT` | Server port | `8086` |
| `MENTORSHIP_DB_NAME` | Database name | `mentorship_db` |
| `MAX_ACTIVE_MENTORSHIPS` | Max active mentorships per user | `5` |

### Gamification Service

| Variable | Description | Default |
|----------|-------------|---------|
| `GAMIFICATION_SERVER_PORT` | Server port | `8087` |
| `GAMIFICATION_DB_NAME` | Database name | `gamification_db` |
| `XP_PER_POST` | XP awarded per post | `10` |
| `XP_PER_LIKE` | XP per like received | `2` |
| `XP_PER_COMMENT` | XP per comment | `5` |

### Notification Service

| Variable | Description | Default |
|----------|-------------|---------|
| `NOTIFICATION_SERVER_PORT` | Server port | `8088` |
| `NOTIFICATION_DB_NAME` | Database name | `notification_db` |
| `NOTIFICATION_RETENTION_DAYS` | Days to keep notifications | `90` |

## 8. Eureka Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EUREKA_HOST` | Eureka server hostname | `discovery-service` |
| `EUREKA_PORT` | Eureka server port | `8761` |

## 9. Config Service Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CONFIG_SERVER_PORT` | Config server port | `8888` |
| `CONFIG_GIT_URI` | Git repository URI | — |

## 10. Monitoring Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PROMETHEUS_PORT` | Prometheus port | `9090` |
| `GRAFANA_PORT` | Grafana port | `3000` |
| `GRAFANA_ADMIN_USER` | Grafana admin username | `admin` |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password | `admin` |

## 11. Example .env File

```bash
# Infrastructure
POSTGRES_USER=pitaya
POSTGRES_PASSWORD=MySecurePass123!
REDIS_PASSWORD=RedisSecurePass456!
RABBITMQ_USER=pitaya
RABBITMQ_DEFAULT_PASS=RabbitSecurePass789!

# JWT Keys
JWT_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----"
JWT_PUBLIC_KEY="-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----"

# Active Profile
SPRING_PROFILES_ACTIVE=prod

# Logging
LOG_LEVEL=INFO
LOGSTASH_HOST=logstash
LOGSTASH_PORT=5000
```

## 12. Security Classifications

| Category | Examples | Storage |
|----------|----------|---------|
| **Critical** | JWT private keys, DB passwords | Kubernetes secrets / Vault |
| **High** | API keys, Redis passwords | Environment variables |
| **Medium** | Hostnames, ports | Config maps |
| **Low** | Timeouts, limits, features | Application config |
