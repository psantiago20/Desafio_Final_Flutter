# Microservices Architecture

## 1. Objective

Document the complete microservices decomposition of the Pitaya platform, detailing each service's responsibilities, boundaries, communication patterns, and data ownership.

## 2. Service Map

```
                    ┌──────────────────────┐
                    │   API Gateway :8080   │
                    │  Spring Cloud Gateway │
                    └──────┬───────┬───────┘
                           │       │
              ┌────────────┘       └────────────┐
              ▼                                  ▼
     ┌─────────────────┐              ┌─────────────────┐
     │  Discovery Svc   │              │  Config Svc     │
     │  Eureka :8761    │◄────────────►│  :8888          │
     └─────────────────┘              └─────────────────┘
              │                                  │
              ▼                                  ▼
     ┌─────────────────────────────────────────────────┐
     │              Message Broker                      │
     │   RabbitMQ :5672 / Kafka :9092                   │
     └─────────────────────────────────────────────────┘
              │     │     │     │     │     │     │
    ┌─────────┘     │     │     │     │     │     └──────────┐
    ▼               ▼     ▼     ▼     ▼     ▼                ▼
┌────────┐  ┌────────┐  ┌──────┐  ┌─────┐  ┌──────┐  ┌──────────┐
│ Auth   │  │ User   │  │ Post │  │Group│  │Library│  │Mentorship│
│ :8081  │  │ :8082  │  │:8083 │  │:8084│  │:8085  │  │ :8086    │
└───┬────┘  └───┬────┘  └──┬───┘  └──┬──┘  └───┬───┘  └────┬─────┘
    │           │          │         │         │           │
    ▼           ▼          ▼         ▼         ▼           ▼
┌──────────────────────────────────────────────────────────────┐
│                    PostgreSQL (per service)                   │
├──────────────────────────────────────────────────────────────┤
│                    Redis (shared cache)                       │
│                    Gamification :8087                         │
│                    Notification :8088                         │
└──────────────────────────────────────────────────────────────┘
```

## 3. Service Breakdown

### 3.1 Auth Service (`pitaya-auth-service`)
- **Port:** 8081
- **Database:** PostgreSQL (auth_db)
- **Cache:** Redis (sessions, rate limits)
- **Dependencies:** None (standalone)
- **Responsibilities:**
  - User registration and authentication
  - JWT and Refresh Token management
  - Password hashing and validation
  - RBAC role assignment
  - Rate limiting per user/IP

### 3.2 User Service (`pitaya-user-service`)
- **Port:** 8082
- **Database:** PostgreSQL (user_db)
- **Cache:** Redis (profile cache)
- **Dependencies:** Auth Service
- **Responsibilities:**
  - Academic profile management
  - Follower/following graph
  - Interest management
  - Social links (Lattes, ORCID, GitHub, LinkedIn)
  - Profile search and discovery

### 3.3 Post Service (`pitaya-post-service`)
- **Port:** 8083
- **Database:** PostgreSQL (post_db)
- **Cache:** Redis (timeline cache, trending topics)
- **Dependencies:** Auth Service, User Service
- **Responsibilities:**
  - Post CRUD operations
  - Comments, likes, reposts
  - Hashtag extraction and indexing
  - Timeline generation
  - Trending topics computation

### 3.4 Group Service (`pitaya-group-service`)
- **Port:** 8084
- **Database:** PostgreSQL (group_db)
- **Cache:** Redis (member cache)
- **Dependencies:** Auth Service, User Service
- **Responsibilities:**
  - Study group management
  - Group roles and permissions
  - Invitation system
  - Content moderation
  - Member management

### 3.5 Library Service (`pitaya-library-service`)
- **Port:** 8085
- **Database:** PostgreSQL (library_db)
- **Cache:** Redis (file metadata cache)
- **Dependencies:** Auth Service, User Service
- **Responsibilities:**
  - PDF and file upload/storage
  - Material categorization
  - Video and link management
  - Content search and filtering
  - File versioning

### 3.6 Mentorship Service (`pitaya-mentorship-service`)
- **Port:** 8086
- **Database:** PostgreSQL (mentorship_db)
- **Cache:** Redis (session cache)
- **Dependencies:** Auth Service, User Service, Notification Service
- **Responsibilities:**
  - Mentorship program management
  - Session scheduling and calendar
  - Feedback collection
  - Mentor/mentee matching
  - Session status tracking

### 3.7 Gamification Service (`pitaya-gamification-service`)
- **Port:** 8087
- **Database:** PostgreSQL (gamification_db)
- **Cache:** Redis (leaderboard cache)
- **Dependencies:** Auth Service, Post Service
- **Responsibilities:**
  - XP points calculation
  - Badge management
  - Ranking computation
  - Level progression
  - Achievement tracking

### 3.8 Notification Service (`pitaya-notification-service`)
- **Port:** 8088
- **Database:** PostgreSQL (notification_db)
- **Cache:** Redis (notification queue)
- **Dependencies:** Message Broker
- **Responsibilities:**
  - Event consumption from broker
  - Notification delivery (in-app, email future)
  - Notification preferences
  - Read/unread tracking
  - Notification history

## 4. Data Ownership

| Service | Owns | Shares via Event |
|---------|------|-----------------|
| Auth | Credentials, roles | USER_REGISTERED |
| User | Profiles, social graph | PROFILE_UPDATED |
| Post | Posts, comments, likes | POST_CREATED, COMMENT_ADDED, POST_LIKED |
| Group | Groups, members | GROUP_CREATED |
| Library | Materials | — |
| Mentorship | Sessions | MENTORSHIP_SCHEDULED |
| Gamification | XP, badges | BADGE_UNLOCKED |
| Notification | Notifications | NOTIFICATION_SENT |

## 5. Inter-Service Communication

### 5.1 Synchronous (OpenFeign)
```
User Service ──GET /api/v1/users/{id}──► Auth Service
Post Service  ──GET /api/v1/users/{id}──► User Service
```

### 5.2 Asynchronous (Events)
```
Auth Service ──USER_REGISTERED──► RabbitMQ ──► User Service
Post Service ──POST_CREATED────► RabbitMQ ──► Gamification Service
```

## 6. Resilience Patterns

| Pattern | Component | Configuration |
|---------|-----------|--------------|
| Circuit Breaker | Resilience4j | Sliding window, 50% threshold |
| Retry | Resilience4j | 3 attempts, exponential backoff |
| Timeout | Resilience4j | 2s default, 5s for heavy ops |
| Bulkhead | Resilience4j | 10 concurrent calls per service |
| Rate Limiter | Resilience4j | 100 req/min per user |

## 7. Health Checks

Each service exposes:
```
GET /actuator/health
GET /actuator/info
GET /actuator/metrics
GET /actuator/prometheus
```

## 8. Logging Pattern

Standardized structured logging with MDC:

```json
{
  "timestamp": "2026-05-14T12:00:00Z",
  "level": "INFO",
  "service": "pitaya-auth-service",
  "traceId": "abc123",
  "spanId": "def456",
  "userId": "uuid",
  "message": "User registered successfully",
  "duration": 45
}
```

## 9. Service Template (Spring Boot)

```java
@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients
public class AuthServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
```

## 10. GitFlow Strategy

- **main**: Stable production code
- **develop**: Integration branch
- **feature/{service}-{description}**: Per-service features
- **release/v{major}.{minor}.{patch}**: Release candidates
- **hotfix/{description}**: Emergency fixes from main
