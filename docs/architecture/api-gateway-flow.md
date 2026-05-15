# API Gateway Flow

## 1. Objective

Document the API Gateway architecture using Spring Cloud Gateway, detailing request routing, authentication, rate limiting, and cross-cutting concerns.

## 2. Responsibilities

- Single entry point for all client requests
- Route requests to appropriate microservices
- JWT validation at the gateway level
- Rate limiting per client/user
- Request/response transformation
- CORS management
- Circuit breaker integration
- Request logging and tracing

## 3. Architecture

```
                    ┌─────────────┐
                    │   Client     │
                    │ (Browser/App)│
                    └──────┬──────┘
                           │ HTTPS
                           ▼
                    ┌─────────────┐
                    │ API Gateway  │
                    │ :8080       │
                    │             │
                    │ ┌─────────┐ │
                    │ │ Security │ │
                    │ │ Filters  │ │
                    │ └─────────┘ │
                    │ ┌─────────┐ │
                    │ │ Rate     │ │
                    │ │ Limiter  │ │
                    │ └─────────┘ │
                    │ ┌─────────┐ │
                    │ │ Router   │ │
                    │ └─────────┘ │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   ┌────────────┐  ┌────────────┐  ┌────────────┐
   │ Auth Svc   │  │ User Svc   │  │ Post Svc   │
   │ :8081      │  │ :8082      │  │ :8083      │
   └────────────┘  └────────────┘  └────────────┘
```

## 4. Route Configuration

### 4.1 application.yml

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: lb://pitaya-auth-service
          predicates:
            - Path=/api/v1/auth/**
          filters:
            - StripPrefix=1
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 100
                redis-rate-limiter.burstCapacity: 200

        - id: user-service
          uri: lb://pitaya-user-service
          predicates:
            - Path=/api/v1/users/**
          filters:
            - StripPrefix=1
            - JwtAuthentication
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 50
                redis-rate-limiter.burstCapacity: 100

        - id: post-service
          uri: lb://pitaya-post-service
          predicates:
            - Path=/api/v1/posts/**
          filters:
            - StripPrefix=1
            - JwtAuthentication
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 30
                redis-rate-limiter.burstCapacity: 60

        - id: group-service
          uri: lb://pitaya-group-service
          predicates:
            - Path=/api/v1/groups/**
          filters:
            - StripPrefix=1
            - JwtAuthentication

        - id: library-service
          uri: lb://pitaya-library-service
          predicates:
            - Path=/api/v1/library/**
          filters:
            - StripPrefix=1
            - JwtAuthentication

        - id: mentorship-service
          uri: lb://pitaya-mentorship-service
          predicates:
            - Path=/api/v1/mentorships/**
          filters:
            - StripPrefix=1
            - JwtAuthentication

        - id: gamification-service
          uri: lb://pitaya-gamification-service
          predicates:
            - Path=/api/v1/gamification/**
          filters:
            - StripPrefix=1
            - JwtAuthentication

        - id: notification-service
          uri: lb://pitaya-notification-service
          predicates:
            - Path=/api/v1/notifications/**
          filters:
            - StripPrefix=1
            - JwtAuthentication

        - id: swagger
          uri: lb://pitaya-auth-service
          predicates:
            - Path=/swagger-ui/**, /v3/api-docs/**
          filters:
            - StripPrefix=0
```

## 5. Global Filters

### 5.1 JWT Authentication Filter

```java
@Component
public class JwtAuthenticationGatewayFilterFactory
    extends AbstractGatewayFilterFactory<Object> {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public GatewayFilter apply(Object config) {
        return (exchange, chain) -> {
            String path = exchange.getRequest().getURI().getPath();

            // Skip auth endpoints
            if (path.startsWith("/api/v1/auth/")) {
                return chain.filter(exchange);
            }

            String token = extractToken(exchange.getRequest());
            if (token == null || !jwtTokenProvider.validateToken(token)) {
                return unauthorized(exchange, "Invalid or expired token");
            }

            Claims claims = jwtTokenProvider.getClaims(token);
            exchange.getRequest().mutate()
                .header("X-User-Id", claims.getSubject())
                .header("X-User-Role", claims.get("role", String.class));

            return chain.filter(exchange);
        };
    }
}
```

### 5.2 Request Logging Filter

```java
@Component
@Slf4j
public class LoggingGlobalFilter implements GlobalFilter, Ordered {

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        log.info("Request: {} {} from {}",
            request.getMethod(),
            request.getURI().getPath(),
            request.getRemoteAddress());

        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            ServerHttpResponse response = exchange.getResponse();
            log.info("Response: {} for {} {} ({}ms)",
                response.getStatusCode(),
                request.getMethod(),
                request.getURI().getPath(),
                System.currentTimeMillis() - startTime);
        }));
    }
}
```

### 5.3 CORS Configuration

```yaml
spring:
  cloud:
    gateway:
      globalcors:
        corsConfigurations:
          '[/**]':
            allowedOrigins: "http://localhost:3000"
            allowedMethods:
              - GET
              - POST
              - PUT
              - DELETE
              - PATCH
              - OPTIONS
            allowedHeaders:
              - Authorization
              - Content-Type
              - X-Requested-With
            allowCredentials: true
            maxAge: 3600
```

## 6. Rate Limiting

### 6.1 Redis-Based Rate Limiter

```yaml
spring:
  cloud:
    gateway:
      routes:
        - filters:
            - name: RequestRateLimiter
              args:
                redis-rate-limiter.replenishRate: 50
                redis-rate-limiter.burstCapacity: 100
                redis-rate-limiter.requestedTokens: 1
```

### 6.2 Key Resolver

```java
@Bean
public KeyResolver userKeyResolver() {
    return exchange -> {
        String userId = exchange.getRequest().getHeaders()
            .getFirst("X-User-Id");
        if (userId != null) {
            return Mono.just(userId);
        }
        return Mono.just(exchange.getRequest().getRemoteAddress()
            .getAddress().getHostAddress());
    };
}
```

## 7. Circuit Breaker

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: post-service
          filters:
            - name: CircuitBreaker
              args:
                name: postServiceCircuitBreaker
                fallbackUri: forward:/fallback/posts
```

## 8. Standard Response Format

All gateway responses follow the standard envelope:

```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {},
  "timestamp": "2026-05-14T12:00:00Z"
}
```

### Error Response

```json
{
  "success": false,
  "message": "Invalid or expired token",
  "data": null,
  "timestamp": "2026-05-14T12:00:00Z"
}
```

## 9. Public vs Protected Routes

| Route | Auth Required | Rate Limit |
|-------|--------------|------------|
| POST /api/v1/auth/login | No | 10/min |
| POST /api/v1/auth/register | No | 5/min |
| POST /api/v1/auth/refresh | No | 10/min |
| POST /api/v1/auth/forgot-password | No | 3/min |
| ALL /api/v1/users/** | Yes | 50/min |
| ALL /api/v1/posts/** | Yes | 30/min |
| ALL /api/v1/groups/** | Yes | 30/min |
| ALL /api/v1/library/** | Yes | 20/min |
| ALL /api/v1/mentorships/** | Yes | 20/min |
| ALL /api/v1/gamification/** | Yes | 100/min |
| ALL /api/v1/notifications/** | Yes | 60/min |

## 10. Error Handling

### Gateway-Level Error Handling

```java
@Bean
public ErrorWebExceptionHandler globalExceptionHandler() {
    return (exchange, ex) -> {
        HttpStatus status = resolveStatus(ex);
        exchange.getResponse().setStatusCode(status);
        // Return standard error envelope
    };
}
```
