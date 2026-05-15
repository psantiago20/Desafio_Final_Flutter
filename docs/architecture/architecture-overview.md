# Architecture Overview

## 1. Objective

Define the overall architecture of the Pitaya Social Academic Network, a modern, scalable, decoupled platform for academic microblogging, networking, mentorship, and research collaboration.

## 2. Responsibilities

- Define system boundaries and component interactions
- Establish communication patterns between services
- Document deployment topology and infrastructure requirements
- Guide implementation decisions across all layers

## 3. Architecture Style

### 3.1 Event-Driven Architecture (EDA)

The platform uses **Event-Driven Architecture** as its primary communication backbone. Services communicate asynchronously via events, achieving loose coupling, scalability, and resilience.

### 3.2 Microservices Architecture

The backend is decomposed into **8 independent microservices**:
- **Auth Service** — authentication and authorization
- **User Service** — profile and social graph management
- **Post Service** — content publishing and timeline
- **Group Service** — study groups and communities
- **Library Service** — academic material management
- **Mentorship Service** — mentoring sessions
- **Gamification Service** — XP, badges, rankings
- **Notification Service** — event-driven notifications

### 3.3 Frontend Architecture

Single-page application using **Vanilla JavaScript** with:
- Manual component system
- CSS custom properties for theming
- Fetch API for HTTP communication
- LocalStorage/SessionStorage for client state
- Mobile-first responsive design

## 4. Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer / CDN                      │
├─────────────────────────────────────────────────────────────┤
│                     API Gateway (Spring Cloud Gateway)       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐           │
│  │ Auth   │  │ User   │  │ Post   │  │ Group  │           │
│  │ Service│  │ Service│  │ Service│  │ Service│           │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘           │
│      │           │           │           │                 │
│  ┌───┴────┐  ┌───┴────┐  ┌───┴────┐  ┌───┴────┐           │
│  │Library │  │Mentor- │  │Gamifica│  │Notifi- │           │
│  │Service │  │ship    │  │tion    │  │cation  │           │
│  │        │  │Service │  │Service │  │Service │           │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘           │
│      │           │           │           │                 │
│  ┌───┴───────────────────────────────────┴────┐            │
│  │           Message Broker                    │           │
│  │    (RabbitMQ / Apache Kafka)               │           │
│  └─────────────────────────────────────────────┘           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │           Service Discovery (Eureka)                 │    │
│  ├─────────────────────────────────────────────────────┤    │
│  │           Config Service (Spring Cloud Config)       │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ PostgreSQL│  │  Redis   │  │ MongoDB  │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## 5. Communication Patterns

| Pattern | Technology | Usage |
|---------|-----------|-------|
| Synchronous HTTP | OpenFeign / REST | Service-to-service queries |
| Asynchronous Events | RabbitMQ / Kafka | State changes, notifications |
| API Gateway | Spring Cloud Gateway | Single entry point |
| Service Discovery | Netflix Eureka | Dynamic service location |
| Centralized Config | Spring Cloud Config | Externalized configuration |
| Circuit Breaker | Resilience4j | Fault tolerance |
| Cache | Redis | Session, rate limiting, hot data |

## 6. Data Flow

### 6.1 Request Flow (Synchronous)

```
Client → API Gateway → Load Balancer → Service Instance → Database
                          ↓
                   Service Discovery
                          ↓
                   Config Service
```

### 6.2 Event Flow (Asynchronous)

```
Service A → produces event → Message Broker → consumes → Service B
                ↓
         Dead Letter Queue (on failure)
```

## 7. Technology Stack

### 7.1 Backend
- **Java 21** — LTS version with pattern matching, records, sealed classes
- **Spring Boot 3.x** — Production-ready framework
- **Spring Cloud 2023.x** — Distributed systems toolkit
- **Spring Security 6.x** — Authentication and authorization
- **Spring Data JPA** — Database access layer
- **PostgreSQL 16** — Primary relational database
- **Redis 7** — Cache and session store
- **RabbitMQ 3.x / Kafka 3.x** — Message broker
- **Maven** — Build and dependency management
- **Lombok** — Boilerplate reduction
- **MapStruct** — Object mapping
- **OpenFeign** — Declarative HTTP clients
- **Resilience4j** — Circuit breaker and retry
- **SpringDoc OpenAPI** — API documentation

### 7.2 Frontend
- **HTML5** — Semantic markup
- **CSS3** — Custom properties, grid, flexbox
- **JavaScript Vanilla** — No frameworks
- **Fetch API** — HTTP communication
- **LocalStorage/SessionStorage** — Client state

### 7.3 Infrastructure
- **Docker** — Containerization
- **Docker Compose** — Local orchestration
- **Prometheus** — Metrics collection
- **Grafana** — Visualization

## 8. Architectural Decisions

### ADR-001: Event-Driven over Request-Driven
**Context:** Services need to communicate state changes without coupling.
**Decision:** Use asynchronous events for state propagation, synchronous REST for queries.
**Consequence:** Higher resilience, eventual consistency, complex debugging.

### ADR-002: PostgreSQL as Primary Database
**Context:** Academic data has complex relationships requiring ACID compliance.
**Decision:** Use PostgreSQL for all services except caching (Redis).
**Consequence:** Simplified operations, reduced polyglot persistence complexity.

### ADR-003: RabbitMQ as Primary Message Broker
**Context:** Need reliable message delivery with complex routing.
**Decision:** Use RabbitMQ for most events, Kafka for high-throughput analytics events.
**Consequence:** Learning curve for RabbitMQ configuration, excellent routing flexibility.

### ADR-004: Vanilla JavaScript Frontend
**Context:** Educational platform serving as learning resource.
**Decision:** No frontend frameworks — pure HTML, CSS, JS.
**Consequence:** More manual work, better learning outcomes, full control.

## 9. Non-Functional Requirements

| Requirement | Target | Strategy |
|------------|--------|----------|
| Availability | 99.9% | Circuit breaker, retry, redundancy |
| Response Time | <500ms p95 | Caching, async processing |
| Scalability | Horizontal | Stateless services, auto-scaling |
| Security | OWASP Top 10 | JWT, RBAC, validation |
| Observability | Full | Logs, metrics, traces |

## 10. Naming Conventions

### Services
- `pitaya-{service-name}-service` (e.g., `pitaya-auth-service`)

### Packages
- `com.pitaya.{service}` (e.g., `com.pitaya.auth`)

### Git Branches
- `main` — production
- `develop` — integration
- `feature/{issue}-{description}` — new features
- `fix/{issue}-{description}` — bug fixes
- `release/{version}` — release candidates

### Commits
Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat: add user profile endpoint`
- `fix: correct JWT expiration calculation`
- `docs: update API documentation`
- `refactor: extract validation logic`
