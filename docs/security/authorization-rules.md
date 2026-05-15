# Authorization Rules

## 1. Objective

Document the authorization model for the Pitaya platform, including permission checks, access control strategies, and endpoint security configurations.

## 2. Authorization Model

The platform uses **Role-Based Access Control (RBAC)** with hierarchical roles:

```
ADMIN (highest)
  └── PROFESSOR
       └── MENTOR
            └── RESEARCHER
                 └── STUDENT (lowest)
```

Higher roles inherit all permissions from lower roles.

## 3. Permission Annotations

### 3.1 Method-Level Security

```java
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<UserResponse>>> listAllUsers() {
        // Only ADMIN can access
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'MODERATOR')")
    @DeleteMapping("/posts/{id}")
    public ResponseEntity<ApiResponse<Void>> moderatePost(@PathVariable UUID id) {
        // ADMIN and MODERATOR can moderate
    }
}
```

### 3.2 Custom Permission Annotations

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("hasRole('ADMIN') or @securityUtils.isResourceOwner(#id)")
public @interface AdminOrOwner {}

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@PreAuthorize("@securityUtils.isGroupModerator(#groupId)")
public @interface GroupModerator {}
```

## 4. Permission Matrix

### 4.1 Post Permissions

| Action | Public | Author | Follower | Others |
|--------|--------|--------|----------|--------|
| Read PUBLIC post | ✓ | ✓ | ✓ | ✓ |
| Read FOLLOWERS_ONLY post | — | ✓ | ✓ | — |
| Read PRIVATE post | — | ✓ | — | — |
| Create post | — | ✓ | — | — |
| Edit post | — | ✓ | — | — |
| Delete post | — | ✓ | — | — |
| Like post | — | ✓ | ✓ | ✓ |
| Comment | — | ✓ | ✓ | ✓ |

### 4.2 Group Permissions

| Action | OWNER | ADMIN | MODERATOR | MEMBER | Non-Member |
|--------|-------|-------|-----------|--------|------------|
| View group | ✓ | ✓ | ✓ | ✓ | PUBLIC only |
| Post content | ✓ | ✓ | ✓ | ✓ | — |
| Edit group | ✓ | ✓ | — | — | — |
| Delete group | ✓ | — | — | — | — |
| Invite members | ✓ | ✓ | ✓ | — | — |
| Remove members | ✓ | ✓ | — | — | — |
| Change roles | ✓ | ✓ | — | — | — |

### 4.3 Mentorship Permissions

| Action | Mentor | Mentee | ADMIN |
|--------|--------|--------|-------|
| Create request | — | ✓ | — |
| Accept/reject | ✓ | — | ✓ |
| Schedule session | ✓ | ✓ | — |
| Complete session | ✓ | — | ✓ |
| Cancel session | ✓ | ✓ | ✓ |
| Submit feedback | — | ✓ | — |
| View details | ✓ | ✓ | ✓ |

### 4.4 Library Permissions

| Action | Uploader | Group Member | PUBLIC | ADMIN |
|--------|----------|-------------|--------|-------|
| Upload | ✓ | ✓ | — | ✓ |
| View PUBLIC | ✓ | ✓ | ✓ | ✓ |
| View PRIVATE | ✓ | — | — | ✓ |
| Delete own | ✓ | — | — | — |
| Delete any | — | — | — | ✓ |

## 5. Security Utility

```java
@Component("securityUtils")
public class SecurityUtils {

    public boolean isResourceOwner(UUID resourceUserId) {
        String currentUserId = SecurityContextHolder.getContext()
            .getAuthentication().getName();
        return currentUserId.equals(resourceUserId.toString());
    }

    public boolean isGroupModerator(UUID groupId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        UUID userId = UUID.fromString(auth.getName());
        // Check member role in group
        return groupMemberRepository
            .findByGroupIdAndUserId(groupId, userId)
            .map(member -> member.getRole() == MemberRole.OWNER
                || member.getRole() == MemberRole.ADMIN
                || member.getRole() == MemberRole.MODERATOR)
            .orElse(false);
    }

    public boolean hasPermission(UUID resourceUserId, String permission) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isOwner = isResourceOwner(resourceUserId);
        boolean hasRole = auth.getAuthorities().stream()
            .anyMatch(a -> a.getAuthority().equals(permission));
        return isOwner || hasRole;
    }
}
```

## 6. Endpoint Security Configuration

```java
@Configuration
@EnableMethodSecurity
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                // Public endpoints
                .requestMatchers(POST, "/api/v1/auth/login").permitAll()
                .requestMatchers(POST, "/api/v1/auth/register").permitAll()
                .requestMatchers(POST, "/api/v1/auth/refresh").permitAll()
                .requestMatchers(POST, "/api/v1/auth/forgot-password").permitAll()
                .requestMatchers(POST, "/api/v1/auth/reset-password").permitAll()

                // Swagger
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers("/actuator/**").permitAll()

                // Admin endpoints
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")

                // Authenticated endpoints
                .anyRequest().authenticated()
            )
            .oauth2ResourceServer(oauth2 -> oauth2
                .jwt(Customizer.withDefaults())
            );
        return http.build();
    }
}
```

## 7. Role Hierarchy

```java
@Bean
public RoleHierarchy roleHierarchy() {
    String hierarchy = """
        ROLE_ADMIN > ROLE_PROFESSOR
        ROLE_PROFESSOR > ROLE_MENTOR
        ROLE_MENTOR > ROLE_RESEARCHER
        ROLE_RESEARCHER > ROLE_STUDENT
    """;
    return new RoleHierarchyImpl(hierarchy);
}

@Bean
public MethodSecurityExpressionHandler methodSecurityExpressionHandler(
        RoleHierarchy roleHierarchy) {
    DefaultMethodSecurityExpressionHandler handler =
        new DefaultMethodSecurityExpressionHandler();
    handler.setRoleHierarchy(roleHierarchy);
    return handler;
}
```

## 8. Data-Level Filtering

```java
// Only return posts the user can see
@Query("""
    SELECT p FROM Post p
    WHERE p.visibility = 'PUBLIC'
       OR p.userId = :currentUserId
       OR (p.visibility = 'FOLLOWERS_ONLY'
           AND p.userId IN (
               SELECT f.followingId FROM Follow f
               WHERE f.followerId = :currentUserId
           ))
    ORDER BY p.createdAt DESC
""")
Page<Post> findAccessiblePosts(@Param("currentUserId") UUID currentUserId, Pageable pageable);
```
