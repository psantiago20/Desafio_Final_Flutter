# Backend Structure

## 1. Objective

Document the complete backend project structure, build configuration, dependency management, and development conventions for the Pitaya platform.

## 2. Project Structure

```
backend/
├── pom.xml                          # Parent POM (multi-module)
├── .env.example                     # Environment variables template
├── .mvn/
│   └── jvm.config
│
├── gateway-service/                 # Spring Cloud Gateway
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/com/pitaya/gateway/
│       │   │   ├── GatewayApplication.java
│       │   │   ├── config/
│       │   │   │   ├── GatewayConfig.java
│       │   │   │   ├── RedisRateLimiterConfig.java
│       │   │   │   └── CorsConfig.java
│       │   │   ├── filter/
│       │   │   │   ├── JwtAuthenticationFilter.java
│       │   │   │   ├── LoggingFilter.java
│       │   │   │   └── RateLimitingFilter.java
│       │   │   ├── security/
│       │   │   │   ├── JwtTokenProvider.java
│       │   │   │   └── SecurityConfig.java
│       │   │   └── handler/
│       │   │       └── GlobalErrorHandler.java
│       │   └── resources/
│       │       ├── application.yml
│       │       ├── application-dev.yml
│       │       └── bootstrap.yml
│       └── test/
│
├── discovery-service/               # Netflix Eureka
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/com/pitaya/discovery/
│       │   │   └── DiscoveryApplication.java
│       │   └── resources/
│       │       └── application.yml
│       └── test/
│
├── config-service/                  # Spring Cloud Config
│   ├── pom.xml
│   └── src/
│       ├── main/
│       │   ├── java/com/pitaya/config/
│       │   │   └── ConfigApplication.java
│       │   └── resources/
│       │       ├── application.yml
│       │       └── config/
│       │           ├── auth-service.yml
│       │           ├── user-service.yml
│       │           ├── post-service.yml
│       │           ├── group-service.yml
│       │           ├── library-service.yml
│       │           ├── mentorship-service.yml
│       │           ├── gamification-service.yml
│       │           └── notification-service.yml
│       └── test/
│
├── shared/                          # Shared library
│   ├── pom.xml
│   └── src/main/java/com/pitaya/shared/
│       ├── dto/
│       │   ├── ApiResponse.java
│       │   ├── PagedResponse.java
│       │   └── ErrorResponse.java
│       ├── event/
│       │   ├── EventEnvelope.java
│       │   ├── BaseEvent.java
│       │   └── events/
│       │       ├── UserRegisteredEvent.java
│       │       ├── ProfileUpdatedEvent.java
│       │       ├── PostCreatedEvent.java
│       │       ├── CommentAddedEvent.java
│       │       ├── PostLikedEvent.java
│       │       ├── GroupCreatedEvent.java
│       │       ├── MentorshipScheduledEvent.java
│       │       ├── BadgeUnlockedEvent.java
│       │       └── NotificationSentEvent.java
│       ├── exception/
│       │   ├── GlobalExceptionHandler.java
│       │   ├── ResourceNotFoundException.java
│       │   ├── BadRequestException.java
│       │   ├── UnauthorizedException.java
│       │   └── ForbiddenException.java
│       ├── util/
│       │   ├── DateUtils.java
│       │   └── ValidationUtils.java
│       └── config/
│           ├── JacksonConfig.java
│           └── LoggingConfig.java
│
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

## 3. Internal Service Structure (Template)

Each service follows this structure:

```
service-name/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/com/pitaya/{service}/
    │   │   ├── {Service}Application.java
    │   │   │
    │   │   ├── config/
    │   │   │   ├── SecurityConfig.java
    │   │   │   ├── JpaConfig.java
    │   │   │   ├── RabbitMqConfig.java
    │   │   │   ├── RedisConfig.java
    │   │   │   ├── SwaggerConfig.java
    │   │   │   └── Resilience4jConfig.java
    │   │   │
    │   │   ├── controller/
    │   │   │   ├── {Entity}Controller.java
    │   │   │   └── HealthController.java
    │   │   │
    │   │   ├── dto/
    │   │   │   ├── request/
    │   │   │   │   ├── Create{Entity}Request.java
    │   │   │   │   ├── Update{Entity}Request.java
    │   │   │   │   └── {Entity}FilterRequest.java
    │   │   │   └── response/
    │   │   │       ├── {Entity}Response.java
    │   │   │       └── {Entity}SummaryResponse.java
    │   │   │
    │   │   ├── entity/
    │   │   │   ├── {Entity}.java
    │   │   │   └── {RelatedEntity}.java
    │   │   │
    │   │   ├── repository/
    │   │   │   ├── {Entity}Repository.java
    │   │   │   └── {Entity}CustomRepository.java
    │   │   │
    │   │   ├── service/
    │   │   │   ├── {Entity}Service.java
    │   │   │   └── impl/
    │   │   │       └── {Entity}ServiceImpl.java
    │   │   │
    │   │   ├── mapper/
    │   │   │   ├── {Entity}Mapper.java
    │   │   │   └── {Entity}MapperImpl.java (generated)
    │   │   │
    │   │   ├── security/
    │   │   │   ├── JwtTokenProvider.java
    │   │   │   └── CurrentUser.java (annotation)
    │   │   │
    │   │   ├── event/
    │   │   │   ├── producer/
    │   │   │   │   └── {Service}EventProducer.java
    │   │   │   └── consumer/
    │   │   │       └── {Related}EventConsumer.java
    │   │   │
    │   │   ├── exception/
    │   │   │   └── {Service}ExceptionHandler.java
    │   │   │
    │   │   ├── validation/
    │   │   │   ├── {Entity}Validator.java
    │   │   │   └── UniqueEmailValidator.java
    │   │   │
    │   │   └── util/
    │   │       └── {Service}Utils.java
    │   │
    │   └── resources/
    │       ├── application.yml
    │       ├── application-dev.yml
    │       ├── application-prod.yml
    │       ├── bootstrap.yml
    │       └── db/migration/
    │           ├── V1__create_users_table.sql
    │           └── V2__add_profile_fields.sql
    │
    └── test/
        └── java/com/pitaya/{service}/
            ├── controller/
            ├── service/
            ├── repository/
            └── {Service}ApplicationTests.java
```

## 4. Parent POM Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.pitaya</groupId>
    <artifactId>pitaya-backend</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.5</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>21</java.version>
        <spring-cloud.version>2023.0.1</spring-cloud.version>
        <mapstruct.version>1.5.5.Final</mapstruct.version>
        <lombok.version>1.18.32</lombok.version>
        <jjwt.version>0.12.5</jjwt.version>
        <testcontainers.version>1.19.7</testcontainers.version>
    </properties>

    <modules>
        <module>shared</module>
        <module>discovery-service</module>
        <module>config-service</module>
        <module>gateway-service</module>
        <module>services/auth-service</module>
        <module>services/user-service</module>
        <module>services/post-service</module>
        <module>services/group-service</module>
        <module>services/library-service</module>
        <module>services/mentorship-service</module>
        <module>services/gamification-service</module>
        <module>services/notification-service</module>
    </modules>
</project>
```

## 5. Dependencies (Per Service POM)

```xml
<dependencies>
    <!-- Spring Boot Starters -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-actuator</artifactId>
    </dependency>

    <!-- Spring Cloud -->
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-config</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-circuitbreaker-resilience4j</artifactId>
    </dependency>

    <!-- Database -->
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>

    <!-- Redis -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-redis</artifactId>
    </dependency>

    <!-- RabbitMQ -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-amqp</artifactId>
    </dependency>

    <!-- Security -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>${jjwt.version}</version>
    </dependency>

    <!-- Lombok -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>

    <!-- MapStruct -->
    <dependency>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct</artifactId>
        <version>${mapstruct.version}</version>
    </dependency>

    <!-- Pitaya Shared -->
    <dependency>
        <groupId>com.pitaya</groupId>
        <artifactId>pitaya-shared</artifactId>
        <version>${project.version}</version>
    </dependency>

    <!-- Test -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
    <dependency>
        <groupId>org.testcontainers</groupId>
        <artifactId>postgresql</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

## 6. Build Configuration

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <excludes>
                    <exclude>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                    </exclude>
                </excludes>
            </configuration>
        </plugin>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <configuration>
                <source>21</source>
                <target>21</target>
                <annotationProcessorPaths>
                    <path>
                        <groupId>org.projectlombok</groupId>
                        <artifactId>lombok</artifactId>
                        <version>${lombok.version}</version>
                    </path>
                    <path>
                        <groupId>org.mapstruct</groupId>
                        <artifactId>mapstruct-processor</artifactId>
                        <version>${mapstruct.version}</version>
                    </path>
                </annotationProcessorPaths>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## 7. Application Patterns

### 7.1 Entity Pattern

```java
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false, length = 100)
    private String fullName;

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    @Column(nullable = false)
    private boolean enabled = true;

    @CreationTimestamp
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
```

### 7.2 Repository Pattern

```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);

    @Query("SELECT u FROM User u WHERE u.role = :role")
    List<User> findAllByRole(@Param("role") Role role);
}
```

### 7.3 Service Pattern

```java
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final UserEventProducer eventProducer;

    @Override
    @Transactional(readOnly = true)
    public UserResponse findById(UUID id) {
        User user = userRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("User not found: " + id));
        return userMapper.toResponse(user);
    }

    @Override
    public UserResponse create(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email already registered");
        }

        User user = userMapper.toEntity(request);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user = userRepository.save(user);

        eventProducer.publishUserRegistered(user);
        return userMapper.toResponse(user);
    }
}
```

### 7.4 Controller Pattern

```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
@Slf4j
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> findById(@PathVariable UUID id) {
        UserResponse response = userService.findById(id);
        return ResponseEntity.ok(ApiResponse.success("User found", response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> create(
            @Valid @RequestBody CreateUserRequest request) {
        UserResponse response = userService.create(request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("User created", response));
    }
}
```

### 7.5 API Response Pattern

```java
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private LocalDateTime timestamp;

    public static <T> ApiResponse<T> success(String message, T data) {
        return ApiResponse.<T>builder()
            .success(true)
            .message(message)
            .data(data)
            .timestamp(LocalDateTime.now())
            .build();
    }

    public static <T> ApiResponse<T> error(String message) {
        return ApiResponse.<T>builder()
            .success(false)
            .message(message)
            .data(null)
            .timestamp(LocalDateTime.now())
            .build();
    }
}
```

## 8. Logging Configuration

### 8.1 logback-spring.xml

```xml
<configuration>
    <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <includeMdcKeyName>traceId</includeMdcKeyName>
            <includeMdcKeyName>userId</includeMdcKeyName>
            <includeMdcKeyName>serviceName</includeMdcKeyName>
        </encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="JSON"/>
    </root>
</configuration>
```

## 9. Testing Conventions

| Test Type | Location | Framework | Pattern |
|-----------|----------|-----------|---------|
| Unit | `src/test/java/.../service/` | JUnit 5 + Mockito | `given/when/then` |
| Integration | `src/test/java/.../repository/` | Testcontainers | `@DataJpaTest` |
| Controller | `src/test/java/.../controller/` | MockMvc | `@WebMvcTest` |
| Contract | Contract tests | Spring Cloud Contract | Consumer-driven |

## 10. Development Commands

```bash
# Build all services
mvn clean install -DskipTests

# Run a specific service
mvn spring-boot:run -pl services/auth-service

# Run all tests
mvn test

# Build Docker images
mvn spring-boot:build-image -pl services/auth-service
```
