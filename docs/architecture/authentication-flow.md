# Authentication Flow

## 1. Objective

Document the complete authentication and authorization flow of the Pitaya platform, from user registration to token management and role-based access control.

## 2. Responsibilities

- Define the authentication sequence
- Document JWT and Refresh Token lifecycle
- Detail RBAC implementation
- Describe token validation at gateway and service levels

## 3. Authentication Flows

### 3.1 Registration Flow

```
Client                    Auth Service                    Database
  │                          │                              │
  │  POST /api/v1/auth/      │                              │
  │  register                │                              │
  │─────────────────────────►│                              │
  │                          │  Validate input              │
  │                          │  Check email uniqueness      │
  │                          │──────────────────────────────►
  │                          │◄─────────────────────────────│
  │                          │                              │
  │                          │  Hash password (BCrypt)      │
  │                          │  Create user entity          │
  │                          │  Assign default role         │
  │                          │──────────────────────────────►
  │                          │◄─────────────────────────────│
  │                          │                              │
  │                          │  Publish USER_REGISTERED     │
  │                          │  event                       │
  │                          │────► RabbitMQ ───────────────►│
  │                          │                              │
  │  { success: true,        │                              │
  │    message: "Registered" }│                             │
  │◄─────────────────────────│                              │
```

### 3.2 Login Flow

```
Client                    API Gateway               Auth Service            Redis
  │                          │                          │                    │
  │ POST /api/v1/auth/login  │                          │                    │
  │─────────────────────────►│                          │                    │
  │                          │ Route to auth-service    │                    │
  │                          │──────────────────────────►│                    │
  │                          │                          │                    │
  │                          │                          │ Validate credentials│
  │                          │                          │ Verify password     │
  │                          │                          │ (BCrypt)            │
  │                          │                          │                    │
  │                          │                          │ Generate Access JWT │
  │                          │                          │ Generate Refresh JWT│
  │                          │                          │ Store refresh token │
  │                          │                          │────────────────────►│
  │                          │                          │◄───────────────────│
  │                          │                          │                    │
  │                          │  { accessToken,          │                    │
  │                          │    refreshToken,          │                    │
  │                          │    user }                 │                    │
  │◄─────────────────────────│◄──────────────────────────│                    │
```

### 3.3 Token Refresh Flow

```
Client                    API Gateway               Auth Service            Redis
  │                          │                          │                    │
  │ POST /api/v1/auth/refresh│                          │                    │
  │ { refreshToken }         │                          │                    │
  │─────────────────────────►│                          │                    │
  │                          │ Route to auth-service    │                    │
  │                          │──────────────────────────►│                    │
  │                          │                          │                    │
  │                          │                          │ Validate refresh   │
  │                          │                          │ token signature    │
  │                          │                          │ Check Redis for    │
  │                          │                          │ stored token       │
  │                          │                          │────────────────────►│
  │                          │                          │◄───────────────────│
  │                          │                          │                    │
  │                          │                          │ Generate new       │
  │                          │                          │ access token       │
  │                          │                          │ Rotate refresh?    │
  │                          │                          │                    │
  │                          │  { accessToken,          │                    │
  │                          │    refreshToken }        │                    │
  │◄─────────────────────────│◄──────────────────────────│                    │
```

### 3.4 Authenticated Request Flow

```
Client                    API Gateway                    Service
  │                          │                              │
  │ GET /api/v1/posts        │                              │
  │ Authorization: Bearer JWT│                              │
  │─────────────────────────►│                              │
  │                          │                              │
  │                          │ Validate JWT signature       │
  │                          │ Check expiration             │
  │                          │ Extract userId, role         │
  │                          │                              │
  │                          │ Forward with headers:        │
  │                          │ X-User-Id, X-User-Role      │
  │                          │──────────────────────────────►
  │                          │                              │
  │                          │  Verify RBAC permissions     │
  │                          │                              │
  │                          │  Process request             │
  │                          │◄─────────────────────────────│
  │◄─────────────────────────│                              │
```

## 4. JWT Token Specification

### 4.1 Access Token

```json
{
  "sub": "a1b2c3d4-...",
  "email": "user@university.edu",
  "role": "STUDENT",
  "permissions": ["read:posts", "write:posts", "read:profile"],
  "iat": 1747219200,
  "exp": 1747222800,
  "iss": "pitaya-auth-service",
  "aud": "pitaya-api"
}
```

**Properties:**
- **Algorithm**: RS256 (asymmetric)
- **Expiration**: 1 hour
- **Storage**: Client memory (not localStorage)
- **Transmission**: Authorization header

### 4.2 Refresh Token

```json
{
  "sub": "a1b2c3d4-...",
  "type": "refresh",
  "iat": 1747219200,
  "exp": 1747305600,
  "iss": "pitaya-auth-service",
  "jti": "unique-token-id"
}
```

**Properties:**
- **Algorithm**: RS256 (asymmetric)
- **Expiration**: 24 hours
- **Storage**: httpOnly cookie (preferred) or secure localStorage
- **Rotation**: Optional rotation on each refresh

## 5. Role Hierarchy

```
ADMIN
  └── PROFESSOR
       └── MENTOR
            └── RESEARCHER
                 └── STUDENT
```

Higher roles inherit permissions from lower roles.

## 6. Permission Matrix

| Permission | STUDENT | RESEARCHER | MENTOR | PROFESSOR | ADMIN |
|------------|---------|------------|--------|-----------|-------|
| read:posts | ✓ | ✓ | ✓ | ✓ | ✓ |
| write:posts | ✓ | ✓ | ✓ | ✓ | ✓ |
| read:profile | ✓ | ✓ | ✓ | ✓ | ✓ |
| write:profile | ✓ | ✓ | ✓ | ✓ | ✓ |
| create:group | ✓ | ✓ | ✓ | ✓ | ✓ |
| moderate:group | ✗ | ✗ | ✓ | ✓ | ✓ |
| create:mentorship | ✓ | ✓ | ✓ | ✓ | ✓ |
| offer:mentorship | ✗ | ✓ | ✓ | ✓ | ✓ |
| read:materials | ✓ | ✓ | ✓ | ✓ | ✓ |
| upload:materials | ✓ | ✓ | ✓ | ✓ | ✓ |
| manage:users | ✗ | ✗ | ✗ | ✗ | ✓ |
| manage:system | ✗ | ✗ | ✗ | ✗ | ✓ |
| view:metrics | ✗ | ✗ | ✗ | ✗ | ✓ |

## 7. Security Implementation

### 7.1 Token Provider

```java
@Component
public class JwtTokenProvider {

    private final RSAPrivateKey privateKey;
    private final RSAPublicKey publicKey;
    private final long accessTokenValidity = 3600000; // 1 hour
    private final long refreshTokenValidity = 86400000; // 24 hours

    public String generateAccessToken(UserDetails user) {
        return Jwts.builder()
            .setSubject(user.getId().toString())
            .claim("email", user.getEmail())
            .claim("role", user.getRole().name())
            .claim("permissions", user.getPermissions())
            .setIssuedAt(new Date())
            .setExpiration(new Date(System.currentTimeMillis() + accessTokenValidity))
            .signWith(privateKey, SignatureAlgorithm.RS256)
            .compact();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                .setSigningKey(publicKey)
                .build()
                .parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }
}
```

### 7.2 Password Encoding

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder(12); // Strength 12
}
```

### 7.3 Security Filter Chain

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/users/**").hasAnyRole("STUDENT", "PROFESSOR", "ADMIN")
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
```

## 8. Rate Limiting by Endpoint

| Endpoint | Limit | Window |
|----------|-------|--------|
| POST /auth/login | 5 attempts | 1 minute |
| POST /auth/register | 3 attempts | 1 hour |
| POST /auth/forgot-password | 2 attempts | 1 hour |
| POST /auth/refresh | 10 attempts | 1 minute |

## 9. Security Headers

```java
http.headers(headers -> headers
    .xssProtection(Customizer.withDefaults())
    .contentSecurityPolicy(csp -> csp
        .policyDirectives("default-src 'self'"))
    .httpStrictTransportSecurity(hsts -> hsts
        .includeSubDomains(true)
        .maxAgeInSeconds(31536000))
);
```

## 10. Best Practices

1. **Never store tokens in localStorage** unless httpOnly cookies unavailable
2. **Rotate refresh tokens** on each use to prevent replay attacks
3. **Use short-lived access tokens** (1 hour maximum)
4. **Validate tokens at gateway** before forwarding to services
5. **Implement token revocation** via Redis blacklist for logout
6. **Use asymmetric keys** (RS256) so services can verify without sharing secrets
7. **Log all authentication attempts** for security auditing
8. **Rate limit aggressively** on authentication endpoints
9. **Sanitize error messages** — never reveal if email exists
10. **Implement account lockout** after 5 failed attempts
