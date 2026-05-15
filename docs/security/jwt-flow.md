# JWT Authentication Flow

## 1. Objective

Document the complete JWT-based authentication implementation, including token generation, validation, refresh flow, and security best practices.

## 2. Token Specifications

### 2.1 Access Token

| Property | Value |
|----------|-------|
| Algorithm | RS256 (RSA Signature with SHA-256) |
| Key Size | 2048 bits |
| Expiration | 1 hour (3600 seconds) |
| Storage | Client memory (not localStorage) |
| Transmission | HTTP Header: `Authorization: Bearer <token>` |

### 2.2 Refresh Token

| Property | Value |
|----------|-------|
| Algorithm | RS256 |
| Expiration | 24 hours (86400 seconds) |
| Storage | httpOnly cookie (preferred) or localStorage |
| Rotation | Optional: rotated on each refresh |

## 3. Key Management

### 3.1 Generate RSA Key Pair

```bash
# Generate private key
openssl genpkey -algorithm RSA -out private-key.pem -pkeyopt rsa_keygen_bits:2048

# Extract public key
openssl rsa -pubout -in private-key.pem -out public-key.pem

# Convert to PKCS#8 format
openssl pkcs8 -topk8 -inform PEM -outform PEM -in private-key.pem -out private-key-pkcs8.pem -nocrypt
```

### 3.2 Java Key Configuration

```yaml
app:
  jwt:
    private-key: |
      -----BEGIN PRIVATE KEY-----
      MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
      -----END PRIVATE KEY-----
    public-key: |
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
      -----END PUBLIC KEY-----
    access-token-expiration: 3600000
    refresh-token-expiration: 86400000
```

### 3.3 Key Loading

```java
@Component
public class JwtKeyProvider {

    @Value("${app.jwt.private-key}")
    private String privateKeyContent;

    @Value("${app.jwt.public-key}")
    private String publicKeyContent;

    private RSAPrivateKey privateKey;
    private RSAPublicKey publicKey;

    @PostConstruct
    public void init() {
        try {
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");

            PKCS8EncodedKeySpec privSpec = new PKCS8EncodedKeySpec(
                Base64.getDecoder().decode(
                    privateKeyContent
                        .replace("-----BEGIN PRIVATE KEY-----", "")
                        .replace("-----END PRIVATE KEY-----", "")
                        .replaceAll("\\s", "")
                )
            );
            this.privateKey = (RSAPrivateKey) keyFactory.generatePrivate(privSpec);

            X509EncodedKeySpec pubSpec = new X509EncodedKeySpec(
                Base64.getDecoder().decode(
                    publicKeyContent
                        .replace("-----BEGIN PUBLIC KEY-----", "")
                        .replace("-----END PUBLIC KEY-----", "")
                        .replaceAll("\\s", "")
                )
            );
            this.publicKey = (RSAPublicKey) keyFactory.generatePublic(pubSpec);
        } catch (Exception e) {
            throw new RuntimeException("Failed to load JWT keys", e);
        }
    }
}
```

## 4. Token Generation

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class JwtTokenProvider {

    private final JwtKeyProvider keyProvider;

    public String generateAccessToken(UserDetails user) {
        Instant now = Instant.now();
        Instant expiry = now.plus(1, ChronoUnit.HOURS);

        return Jwts.builder()
            .issuer("pitaya-auth-service")
            .subject(user.getId().toString())
            .audience().add("pitaya-api").and()
            .issuedAt(Date.from(now))
            .expiration(Date.from(expiry))
            .claim("email", user.getEmail())
            .claim("role", user.getRole().name())
            .claim("permissions", user.getPermissions())
            .claim("scope", "access")
            .signWith(keyProvider.getPrivateKey(), Jwts.SIG.RS256)
            .compact();
    }

    public String generateRefreshToken(UserDetails user) {
        Instant now = Instant.now();
        Instant expiry = now.plus(24, ChronoUnit.HOURS);

        return Jwts.builder()
            .issuer("pitaya-auth-service")
            .subject(user.getId().toString())
            .issuedAt(Date.from(now))
            .expiration(Date.from(expiry))
            .claim("scope", "refresh")
            .id(UUID.randomUUID().toString())
            .signWith(keyProvider.getPrivateKey(), Jwts.SIG.RS256)
            .compact();
    }
}
```

## 5. Token Validation

```java
@Component
@RequiredArgsConstructor
public class JwtTokenValidator {

    private final JwtKeyProvider keyProvider;

    public boolean validateToken(String token) {
        try {
            Claims claims = parseClaims(token);
            return !isTokenExpired(claims) && "access".equals(claims.get("scope"));
        } catch (JwtException | IllegalArgumentException e) {
            log.error("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    public boolean validateRefreshToken(String token) {
        try {
            Claims claims = parseClaims(token);
            return !isTokenExpired(claims) && "refresh".equals(claims.get("scope"));
        } catch (JwtException e) {
            return false;
        }
    }

    public Claims parseClaims(String token) {
        return Jwts.parser()
            .verifyWith(keyProvider.getPublicKey())
            .requireIssuer("pitaya-auth-service")
            .build()
            .parseSignedClaims(token)
            .getPayload();
    }

    private boolean isTokenExpired(Claims claims) {
        return claims.getExpiration().before(new Date());
    }
}
```

## 6. Authentication Filter

```java
@Component
@RequiredArgsConstructor
@Slf4j
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final JwtTokenValidator jwtTokenValidator;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain filterChain)
            throws ServletException, IOException {

        String token = extractToken(request);

        if (token != null && jwtTokenValidator.validateToken(token)) {
            Claims claims = jwtTokenValidator.parseClaims(token);
            UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(
                    claims.getSubject(),
                    null,
                    getAuthorities(claims)
                );
            authentication.setDetails(
                new WebAuthenticationDetailsSource().buildDetails(request)
            );
            SecurityContextHolder.getContext().setAuthentication(authentication);

            MDC.put("userId", claims.getSubject());
            MDC.put("userRole", claims.get("role", String.class));
        }

        filterChain.doFilter(request, response);
        MDC.clear();
    }

    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    private List<GrantedAuthority> getAuthorities(Claims claims) {
        List<String> permissions = claims.get("permissions", List.class);
        return permissions.stream()
            .map(SimpleGrantedAuthority::new)
            .collect(Collectors.toList());
    }
}
```

## 7. Refresh Token Service

```java
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtTokenProvider jwtTokenProvider;

    public String createRefreshToken(User user) {
        String token = jwtTokenProvider.generateRefreshToken(user);

        RefreshToken refreshToken = RefreshToken.builder()
            .userId(user.getId())
            .token(token)
            .expiresAt(Instant.now().plus(24, ChronoUnit.HOURS))
            .build();

        refreshTokenRepository.save(refreshToken);
        return token;
    }

    public AuthResponse refreshAccessToken(String refreshTokenValue) {
        // Validate JWT format
        if (!jwtTokenProvider.validateRefreshToken(refreshTokenValue)) {
            throw new BadRequestException("Invalid refresh token");
        }

        // Check in database
        RefreshToken storedToken = refreshTokenRepository
            .findByToken(refreshTokenValue)
            .orElseThrow(() -> new BadRequestException("Refresh token not found"));

        if (storedToken.isRevoked() || storedToken.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("Refresh token expired or revoked");
        }

        // Rotate: revoke old, create new
        storedToken.setRevoked(true);
        refreshTokenRepository.save(storedToken);

        // Generate new tokens
        User user = userRepository.findById(storedToken.getUserId())
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        String newAccessToken = jwtTokenProvider.generateAccessToken(user);
        String newRefreshToken = createRefreshToken(user);

        return AuthResponse.builder()
            .accessToken(newAccessToken)
            .refreshToken(newRefreshToken)
            .tokenType("Bearer")
            .expiresIn(3600)
            .build();
    }
}
```

## 8. Token Revocation

```java
@Service
@RequiredArgsConstructor
public class TokenRevocationService {

    private final RedisTemplate<String, String> redisTemplate;

    private static final String BLACKLIST_PREFIX = "revoked_token:";

    public void revoke(String tokenId, long expirationTime) {
        Duration ttl = Duration.ofMillis(expirationTime - System.currentTimeMillis());
        redisTemplate.opsForValue()
            .set(BLACKLIST_PREFIX + tokenId, "revoked", ttl);
    }

    public boolean isRevoked(String tokenId) {
        return Boolean.TRUE.equals(
            redisTemplate.hasKey(BLACKLIST_PREFIX + tokenId)
        );
    }
}
```

## 9. Security Headers

```java
http.headers(headers -> headers
    .httpStrictTransportSecurity(hsts -> hsts
        .includeSubDomains(true)
        .maxAgeInSeconds(31536000))
    .contentSecurityPolicy(csp -> csp
        .policyDirectives(
            "default-src 'self'; " +
            "script-src 'self'; " +
            "style-src 'self' 'unsafe-inline'; " +
            "img-src 'self' https:; " +
            "connect-src 'self' https://api.pitaya.com"
        ))
    .xssProtection(xss -> xss
        .headerValue(XXssProtectionHeaderWriter.HeaderValue.ENABLED_MODE_BLOCK))
    .contentTypeOptions(Customizer.withDefaults())
    .frameOptions(frame -> frame.deny())
);
```

## 10. Best Practices

1. **Short-lived access tokens** (1 hour max)
2. **Asymmetric keys** (RS256) for distributed verification
3. **Token rotation** on refresh to prevent replay
4. **Revocation list** in Redis for immediate logout
5. **Never store tokens in localStorage** — use httpOnly cookies
6. **Validate all claims** (issuer, audience, expiry, scope)
7. **Add trace ID** to every request for audit trail
8. **Rate limit** authentication endpoints aggressively
9. **Log all auth failures** with IP and timestamp
10. **Blacklist old keys** after rotation
