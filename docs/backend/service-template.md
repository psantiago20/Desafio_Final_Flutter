# Service Template

## 1. Objective

Provide a complete, reusable service template that enforces consistent architecture, patterns, and conventions across all Pitaya microservices.

## 2. Template Structure

```
{service-name}/
├── pom.xml
├── Dockerfile
├── src/
│   ├── main/
│   │   ├── java/com/pitaya/{service}/
│   │   │   ├── {Service}Application.java
│   │   │   ├── config/
│   │   │   ├── controller/
│   │   │   ├── dto/
│   │   │   ├── entity/
│   │   │   ├── repository/
│   │   │   ├── service/
│   │   │   ├── mapper/
│   │   │   ├── security/
│   │   │   ├── event/
│   │   │   ├── exception/
│   │   │   ├── validation/
│   │   │   └── util/
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-docker.yml
│   │       └── db/migration/
│   └── test/
│       └── java/com/pitaya/{service}/
└── target/
```

## 3. Application Entry Point

```java
package com.pitaya.auth;

@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients(basePackages = "com.pitaya.auth.client")
@EnableCircuitBreaker
@EnableConfigurationProperties
public class AuthServiceApplication {

    @PostConstruct
    public void init() {
        TimeZone.setDefault(TimeZone.getTimeZone("UTC"));
    }

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
```

## 4. Configuration Classes

### 4.1 SecurityConfig

```java
package com.pitaya.auth.config;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtTokenProvider jwtTokenProvider;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(POST, "/api/v1/auth/login", "/api/v1/auth/register").permitAll()
                .requestMatchers(GET, "/api/v1/auth/refresh").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers("/actuator/**").permitAll()
                .anyRequest().authenticated()
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(
                new JwtAuthenticationFilter(jwtTokenProvider),
                UsernamePasswordAuthenticationFilter.class
            );
        return http.build();
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(customUserDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
```

### 4.2 JpaConfig

```java
package com.pitaya.auth.config;

@Configuration
@EnableJpaAuditing
@EnableTransactionManagement
public class JpaConfig {

    @Bean
    public AuditorAware<String> auditorAware() {
        return () -> {
            String userId = MDC.get("userId");
            return Optional.ofNullable(userId).orElse("system");
        };
    }
}
```

### 4.3 RabbitMqConfig

```java
package com.pitaya.auth.config;

@Configuration
@EnableRabbit
@RequiredArgsConstructor
public class RabbitMqConfig {

    private final RabbitMqProperties properties;

    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange("pitaya.user");
    }

    @Bean
    public Queue userRegisteredQueue() {
        return QueueBuilder.durable(properties.getQueues().get("user.registered"))
            .withArgument("x-dead-letter-exchange", "pitaya.dlx")
            .withArgument("x-dead-letter-routing-key", "user.registered.dlq")
            .withArgument("x-max-retries", 3)
            .build();
    }

    @Bean
    public Binding userRegisteredBinding() {
        return BindingBuilder
            .bind(userRegisteredQueue())
            .to(userExchange())
            .with("user.registered");
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        Jackson2JsonMessageConverter converter = new Jackson2JsonMessageConverter();
        converter.setCreateMessageIds(true);
        return converter;
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate template = new RabbitTemplate(connectionFactory);
        template.setMessageConverter(messageConverter());
        template.setRetryTemplate(retryTemplate());
        return template;
    }

    private RetryTemplate retryTemplate() {
        RetryTemplate retry = new RetryTemplate();
        retry.setBackOffPolicy(new ExponentialBackOffPolicy());
        retry.setRetryOperations(new SimpleRetryOperations(3));
        return retry;
    }
}
```

### 4.4 RedisConfig

```java
package com.pitaya.auth.config;

@Configuration
@EnableCaching
@RequiredArgsConstructor
public class RedisConfig {

    private final RedisProperties properties;

    @Bean
    public RedisConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName(properties.getHost());
        config.setPort(properties.getPort());
        return new LettuceConnectionFactory(config);
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate() {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(redisConnectionFactory());
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        return template;
    }

    @Bean
    public CacheManager cacheManager() {
        return RedisCacheManager.builder(redisConnectionFactory())
            .cacheDefaults(defaultCacheConfig())
            .build();
    }

    private RedisCacheConfiguration defaultCacheConfig() {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Duration.ofMinutes(10))
            .disableCachingNullValues();
    }
}
```

## 5. Entity Template

```java
package com.pitaya.auth.entity;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
public class User implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @EqualsAndHashCode.Include
    private UUID id;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false)
    @JsonIgnore
    private String password;

    @Column(nullable = false, length = 150)
    private String fullName;

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private Role role;

    @Column(nullable = false)
    private boolean enabled = true;

    @Column(nullable = false)
    private boolean emailVerified = false;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
    }
}
```

## 6. DTO Pattern

### 6.1 Request DTO

```java
package com.pitaya.auth.dto.request;

@Value
@Builder
@Jacksonized
public class CreateUserRequest {

    @NotBlank(message = "Email is required")
    @Email(message = "Invalid email format")
    @Size(max = 100)
    String email;

    @NotBlank(message = "Password is required")
    @Size(min = 8, max = 100, message = "Password must be 8-100 characters")
    @Pattern(
        regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$",
        message = "Password must contain uppercase, lowercase, and number"
    )
    String password;

    @NotBlank(message = "Full name is required")
    @Size(max = 150)
    String fullName;

    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 50)
    @Pattern(
        regexp = "^[a-zA-Z0-9._-]+$",
        message = "Username can only contain letters, numbers, dots, underscores, and hyphens"
    )
    String username;

    @NotNull(message = "Role is required")
    Role role;

    @Past(message = "Birth date must be in the past")
    @NotNull
    LocalDate birthDate;
}
```

### 6.2 Response DTO

```java
package com.pitaya.auth.dto.response;

@Value
@Builder
@Jacksonized
public class AuthResponse {
    @JsonInclude
    String accessToken;
    @JsonInclude
    String refreshToken;
    String tokenType = "Bearer";
    long expiresIn;
    UserSummaryResponse user;
}

@Value
@Builder
@Jacksonized
public class UserSummaryResponse {
    UUID id;
    String email;
    String fullName;
    String username;
    String role;
    String avatar;
}
```

## 7. Mapper (MapStruct)

```java
package com.pitaya.auth.mapper;

@Mapper(
    componentModel = "spring",
    injectionStrategy = InjectionStrategy.CONSTRUCTOR,
    unmappedSourcePolicy = ReportingPolicy.WARN,
    unmappedTargetPolicy = ReportingPolicy.ERROR
)
public interface UserMapper {

    UserSummaryResponse toSummaryResponse(User user);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "password", ignore = true)
    @Mapping(target = "enabled", constant = "true")
    @Mapping(target = "emailVerified", constant = "false")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    User toEntity(CreateUserRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    @Mapping(target = "password", ignore = true)
    @Mapping(target = "email", ignore = true)
    @Mapping(target = "id", ignore = true)
    void updateEntity(UpdateUserRequest request, @MappingTarget User user);
}
```

## 8. Service Pattern

```java
package com.pitaya.auth.service.impl;

@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenService refreshTokenService;
    private final AuthEventProducer eventProducer;

    @Override
    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        log.debug("Login attempt for email: {}", request.getEmail());

        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new BadRequestException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            log.warn("Failed login attempt for email: {}", request.getEmail());
            throw new BadRequestException("Invalid credentials");
        }

        if (!user.isEnabled()) {
            throw new BadRequestException("Account is disabled");
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = refreshTokenService.createRefreshToken(user);

        log.info("User logged in: {}", user.getId());
        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .tokenType("Bearer")
            .expiresIn(3600)
            .user(userMapper.toSummaryResponse(user))
            .build();
    }

    @Override
    public AuthResponse register(CreateUserRequest request) {
        log.debug("Registering user with email: {}", request.getEmail());

        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email already registered");
        }
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username already taken");
        }

        User user = userMapper.toEntity(request);
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user = userRepository.save(user);

        eventProducer.publishUserRegistered(user);

        log.info("User registered: {}", user.getId());
        return login(new LoginRequest(request.getEmail(), request.getPassword()));
    }
}
```

## 9. Event Producer Template

```java
package com.pitaya.auth.event.producer;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthEventProducer {

    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    public void publishUserRegistered(User user) {
        EventEnvelope<UserRegisteredPayload> event = EventEnvelope.<UserRegisteredPayload>builder()
            .eventId(UUID.randomUUID().toString())
            .eventType(EventType.USER_REGISTERED.name())
            .source("pitaya-auth-service")
            .timestamp(Instant.now())
            .version(1)
            .userId(user.getId().toString())
            .payload(new UserRegisteredPayload(
                user.getEmail(),
                user.getRole().name(),
                user.getFullName(),
                user.getUsername()
            ))
            .build();

        rabbitTemplate.convertAndSend("pitaya.user", "user.registered", event);
        log.info("Published USER_REGISTERED event for user: {}", user.getId());
    }
}
```

## 10. Exception Handler Template

```java
package com.pitaya.auth.exception;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    @ResponseStatus(NOT_FOUND)
    public ResponseEntity<ApiResponse<Void>> handleNotFound(ResourceNotFoundException ex) {
        log.error("Resource not found: {}", ex.getMessage());
        return ResponseEntity.status(NOT_FOUND)
            .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(BadRequestException.class)
    @ResponseStatus(BAD_REQUEST)
    public ResponseEntity<ApiResponse<Void>> handleBadRequest(BadRequestException ex) {
        return ResponseEntity.status(BAD_REQUEST)
            .body(ApiResponse.error(ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(BAD_REQUEST)
    public ResponseEntity<ApiResponse<Map<String, String>>> handleValidation(
            MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
            .forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("Validation failed"));
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(INTERNAL_SERVER_ERROR)
    public ResponseEntity<ApiResponse<Void>> handleGeneric(Exception ex) {
        log.error("Unexpected error", ex);
        return ResponseEntity.status(INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("Internal server error"));
    }
}
```
