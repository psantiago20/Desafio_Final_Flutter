# Spring Cloud Setup

## 1. Objective

Document the configuration and setup of the Spring Cloud ecosystem for the Pitaya platform, including service discovery, centralized configuration, API gateway, and inter-service communication.

## 2. Components

| Component | Technology | Port |
|-----------|-----------|------|
| API Gateway | Spring Cloud Gateway | 8080 |
| Service Discovery | Netflix Eureka | 8761 |
| Config Server | Spring Cloud Config | 8888 |
| Circuit Breaker | Resilience4j | — |
| Load Balancer | Spring Cloud LoadBalancer | — |
| HTTP Client | OpenFeign | — |

## 3. Discovery Service (Eureka)

### 3.1 Application

```java
@SpringBootApplication
@EnableEurekaServer
public class DiscoveryApplication {
    public static void main(String[] args) {
        SpringApplication.run(DiscoveryApplication.class, args);
    }
}
```

### 3.2 Configuration

```yaml
# application.yml
server:
  port: 8761

eureka:
  instance:
    hostname: discovery-service
  client:
    register-with-eureka: false
    fetch-registry: false
  server:
    enable-self-preservation: true
    renewal-percent-threshold: 0.85
```

## 4. Config Service

### 4.1 Application

```java
@SpringBootApplication
@EnableConfigServer
@EnableDiscoveryClient
public class ConfigApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigApplication.class, args);
    }
}
```

### 4.2 Configuration

```yaml
server:
  port: 8888

spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/pitaya/pitaya-config
          default-label: main
          search-paths: '{service}'
    fail-fast: true
```

### 4.3 Service Configuration Example (auth-service.yml)

```yaml
server:
  port: 8081

spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:5432/auth_db
    username: ${DB_USER}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration
  redis:
    host: ${REDIS_HOST:localhost}
    port: 6379
  rabbitmq:
    host: ${RABBIT_HOST:localhost}
    port: 5672
    username: ${RABBIT_USER}
    password: ${RABBIT_PASS}

app:
  jwt:
    private-key: ${JWT_PRIVATE_KEY}
    public-key: ${JWT_PUBLIC_KEY}
    access-token-expiration: 3600000
    refresh-token-expiration: 86400000

eureka:
  client:
    service-url:
      defaultZone: http://discovery-service:8761/eureka/

resilience4j:
  circuitbreaker:
    instances:
      default:
        sliding-window-size: 10
        minimum-number-of-calls: 5
        failure-rate-threshold: 50
        wait-duration-in-open-state: 10s
```

## 5. Bootstrap Configuration

Each service has `bootstrap.yml`:

```yaml
spring:
  application:
    name: pitaya-auth-service
  cloud:
    config:
      uri: http://config-service:8888
      fail-fast: true
      retry:
        initial-interval: 1000
        max-attempts: 5
        multiplier: 2
```

## 6. OpenFeign Configuration

### 6.1 Feign Client Interface

```java
@FeignClient(
    name = "pitaya-user-service",
    path = "/api/v1/users",
    configuration = FeignConfig.class,
    fallbackFactory = UserClientFallbackFactory.class
)
public interface UserClient {

    @GetMapping("/{id}")
    ResponseEntity<ApiResponse<UserResponse>> findById(@PathVariable UUID id);

    @GetMapping("/{id}/profile")
    ResponseEntity<ApiResponse<AcademicProfileResponse>> getAcademicProfile(@PathVariable UUID id);
}
```

### 6.2 Feign Configuration

```java
@Configuration
public class FeignConfig {

    @Bean
    public RequestInterceptor requestInterceptor() {
        return requestTemplate -> {
            RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
            if (attributes instanceof ServletRequestAttributes) {
                HttpServletRequest request = ((ServletRequestAttributes) attributes).getRequest();
                String token = request.getHeader("Authorization");
                if (token != null) {
                    requestTemplate.header("Authorization", token);
                }
                String userId = request.getHeader("X-User-Id");
                if (userId != null) {
                    requestTemplate.header("X-User-Id", userId);
                }
            }
        };
    }

    @Bean
    public Logger.Level feignLoggerLevel() {
        return Logger.Level.HEADERS;
    }
}
```

### 6.3 Fallback Factory

```java
@Component
@Slf4j
public class UserClientFallbackFactory implements FallbackFactory<UserClient> {

    @Override
    public UserClient create(Throwable cause) {
        return id -> {
            log.error("Fallback: Unable to fetch user {}", id, cause);
            return ResponseEntity.ok(ApiResponse.error("Service temporarily unavailable"));
        };
    }
}
```

## 7. Resilience4j Configuration

### 7.1 Circuit Breaker

```yaml
resilience4j:
  circuitbreaker:
    instances:
      userService:
        sliding-window-type: COUNT_BASED
        sliding-window-size: 10
        minimum-number-of-calls: 5
        failure-rate-threshold: 40
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 3
        record-exceptions:
          - java.net.ConnectException
          - feign.FeignException
```

### 7.2 Retry

```yaml
resilience4j:
  retry:
    instances:
      userService:
        max-attempts: 3
        wait-duration: 2s
        exponential-backoff-multiplier: 2
        retry-exceptions:
          - java.net.ConnectException
          - feign.RetryableException
```

### 7.3 Bulkhead

```yaml
resilience4j:
  bulkhead:
    instances:
      default:
        max-concurrent-calls: 20
        max-wait-duration: 10ms
```

### 7.4 TimeLimiter

```yaml
resilience4j:
  timelimiter:
    instances:
      default:
        timeout-duration: 5s
        cancel-running-future: true
```

## 8. Load Balancer

```java
@Bean
@LoadBalanced
public RestTemplate restTemplate() {
    return new RestTemplate();
}

// Usage
String response = restTemplate.getForObject(
    "http://pitaya-user-service/api/v1/users/{id}",
    String.class, userId
);
```

## 9. Service-to-Service Communication Pattern

```
Service A                    Service Discovery              Service B
    │                              │                           │
    │ Resolve "pitaya-user-service"│                           │
    │──────────────────────────────►│                           │
    │                              │                           │
    │ Return available instances   │                           │
    │◄──────────────────────────────│                           │
    │                              │                           │
    │ GET http://pitaya-user-service/api/v1/users/123          │
    │──────────────────────────────────────────────────────────►│
    │                              │                           │
    │◄──────────────────────────────────────────────────────────│
```

## 10. Observability

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus,circuitbreakers
  endpoint:
    health:
      show-details: always
    circuitbreakers:
      enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
    tags:
      application: ${spring.application.name}
```
