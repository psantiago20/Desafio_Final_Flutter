# Roles & Permissions

## 1. Objective

Document all system roles, their hierarchical relationships, and the complete permission set for the Pitaya platform.

## 2. Role Definitions

### 2.1 STUDENT

**Description**: Undergraduate or graduate student consuming academic content and mentorship.

**Can:**
- Read and write posts (microblogging)
- Comment, like, repost
- Join public groups
- Request mentorship
- Upload academic materials
- View and earn badges/XP
- Receive notifications

---

### 2.2 RESEARCHER

**Description**: Academic researcher publishing and collaborating on scientific content.

**Inherits from**: STUDENT

**Additional permissions:**
- Offer mentorship (can become mentor)
- Create research-oriented groups
- Publish scientific articles
- Seek collaboration opportunities
- Access advanced analytics

---

### 2.3 MENTOR

**Description**: Experienced professional or academic who provides guidance.

**Inherits from**: RESEARCHER

**Additional permissions:**
- Accept/reject mentorship requests
- Manage mentorship sessions
- Evaluate mentees
- Set mentorship availability
- View mentee progress

---

### 2.4 PROFESSOR

**Description**: Faculty member teaching and moderating academic content.

**Inherits from**: MENTOR

**Additional permissions:**
- Moderate group content
- Create educational materials
- Manage course-related groups
- Bulk invite students
- Access moderation tools

---

### 2.5 ADMIN

**Description**: System administrator with full platform access.

**Inherits from**: PROFESSOR

**Additional permissions:**
- Manage all users (create, disable, delete)
- Moderate all content (posts, comments, groups)
- View system metrics and logs
- Configure gamification rules
- Manage integrations
- Access admin panel
- Global permission management
- Audit log access

## 3. Permission Enum

```java
public enum Permission {
    // Post permissions
    POST_READ,
    POST_CREATE,
    POST_EDIT,
    POST_DELETE,
    POST_MODERATE,

    // Comment permissions
    COMMENT_READ,
    COMMENT_CREATE,
    COMMENT_DELETE,
    COMMENT_MODERATE,

    // Like permissions
    LIKE_TOGGLE,

    // Repost permissions
    REPOST,

    // Profile permissions
    PROFILE_READ,
    PROFILE_EDIT,
    PROFILE_DELETE,

    // Follow permissions
    FOLLOW,
    UNFOLLOW,

    // Group permissions
    GROUP_CREATE,
    GROUP_EDIT,
    GROUP_DELETE,
    GROUP_MODERATE,
    GROUP_INVITE,
    GROUP_MANAGE_ROLES,

    // Mentorship permissions
    MENTORSHIP_REQUEST,
    MENTORSHIP_ACCEPT,
    MENTORSHIP_MANAGE,
    MENTORSHIP_FEEDBACK,

    // Library permissions
    LIBRARY_UPLOAD,
    LIBRARY_READ,
    LIBRARY_DELETE_OWN,
    LIBRARY_DELETE_ANY,

    // Admin permissions
    USER_MANAGE,
    SYSTEM_CONFIG,
    METRICS_VIEW,
    AUDIT_VIEW,
    GAMIFICATION_CONFIGURE,
    INTEGRATION_MANAGE
}
```

## 4. Role-Permission Mapping

```java
public enum Role {
    STUDENT(
        POST_READ, POST_CREATE,
        COMMENT_READ, COMMENT_CREATE,
        LIKE_TOGGLE, REPOST,
        PROFILE_READ, PROFILE_EDIT,
        FOLLOW, UNFOLLOW,
        GROUP_CREATE, GROUP_INVITE,
        MENTORSHIP_REQUEST, MENTORSHIP_FEEDBACK,
        LIBRARY_UPLOAD, LIBRARY_READ, LIBRARY_DELETE_OWN
    ),
    RESEARCHER(
        STUDENT.permissions,
        GROUP_MODERATE,
        MENTORSHIP_ACCEPT
    ),
    MENTOR(
        RESEARCHER.permissions,
        MENTORSHIP_MANAGE
    ),
    PROFESSOR(
        MENTOR.permissions,
        POST_MODERATE, COMMENT_MODERATE,
        GROUP_MANAGE_ROLES,
        LIBRARY_DELETE_ANY
    ),
    ADMIN(
        PROFESSOR.permissions,
        POST_DELETE, COMMENT_DELETE,
        GROUP_DELETE,
        PROFILE_DELETE,
        USER_MANAGE, SYSTEM_CONFIG,
        METRICS_VIEW, AUDIT_VIEW,
        GAMIFICATION_CONFIGURE, INTEGRATION_MANAGE
    );

    private final Set<Permission> permissions;

    Role(Permission... permissions) {
        this.permissions = Set.of(permissions);
    }

    Role(Set<Permission> base, Permission... additional) {
        Set<Permission> combined = new HashSet<>(base);
        combined.addAll(Set.of(additional));
        this.permissions = Collections.unmodifiableSet(combined);
    }

    public boolean hasPermission(Permission permission) {
        return permissions.contains(permission);
    }
}
```

## 5. Permission Check Service

```java
@Service
public class PermissionService {

    public void checkPermission(UUID userId, Permission required) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!user.getRole().hasPermission(required)) {
            throw new ForbiddenException(
                "User does not have permission: " + required
            );
        }
    }

    public void checkAnyPermission(UUID userId, Permission... permissions) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        boolean hasAny = Arrays.stream(permissions)
            .anyMatch(user.getRole()::hasPermission);

        if (!hasAny) {
            throw new ForbiddenException(
                "User does not have any of the required permissions"
            );
        }
    }

    @PostAuthorize("returnObject == null || hasPermission(returnObject, 'read')")
    public Post findPostWithPermissionCheck(UUID postId) {
        return postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post not found"));
    }
}
```

## 6. Audit Logging

```java
@Aspect
@Component
@Slf4j
public class AuditAspect {

    @AfterReturning("@annotation(auditable)")
    public void logAudit(JoinPoint joinPoint, Auditable auditable) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        AuditLog log = AuditLog.builder()
            .userId(auth.getName())
            .action(auditable.action())
            .resource(auditable.resource())
            .timestamp(Instant.now())
            .details(extractDetails(joinPoint.getArgs()))
            .build();

        auditLogRepository.save(log);
        log.info("Audit: {} {} by user {}",
            auditable.action(), auditable.resource(), auth.getName());
    }
}
```
