# Migrations Guide

## 1. Objective

Document the database migration strategy using Flyway, including naming conventions, execution order, rollback procedures, and best practices for schema evolution.

## 2. Flyway Configuration

### 2.1 Dependencies

```xml
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-database-postgresql</artifactId>
</dependency>
```

### 2.2 Application Configuration

```yaml
spring:
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
    baseline-version: 0
    validate-on-migrate: true
    clean-disabled: true
    out-of-order: false
    encoding: UTF-8
    create-schemas: true
    schemas: public
    table: flyway_schema_history
```

### 2.3 Programmatic Configuration

```java
@Configuration
public class FlywayConfig {

    @Bean
    public Flyway flyway(DataSource dataSource) {
        return Flyway.configure()
            .dataSource(dataSource)
            .locations("classpath:db/migration")
            .baselineOnMigrate(true)
            .baselineVersion("0")
            .validateOnMigrate(true)
            .cleanDisabled(true)
            .outOfOrder(false)
            .table("flyway_schema_history")
            .load();
    }
}
```

## 3. Migration File Naming

```
[Prefix][Version]__[Description].sql

Prefix: V (versioned), U (undo), R (repeatable)

Examples:
V1__create_users_table.sql
V2__add_profile_fields.sql
V3__add_unique_constraint_email.sql
V4__create_indexes.sql
V5__add_hashtag_trgm_index.sql
R__view_user_summary.sql
```

## 4. Migration Directory Structure

```
services/auth-service/src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__add_birth_date_column.sql
├── V3__create_refresh_tokens_table.sql
├── V4__create_password_reset_tokens_table.sql
├── V5__add_user_indexes.sql
└── R__user_views.sql
```

## 5. Migration Examples

### 5.1 Initial Schema (V1)

```sql
-- V1__create_users_table.sql
-- Auth Service initial migration

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('STUDENT', 'PROFESSOR', 'RESEARCHER', 'MENTOR', 'ADMIN');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(100) NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    username VARCHAR(50) NOT NULL,
    role user_role NOT NULL DEFAULT 'STUDENT',
    birth_date DATE NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_users_email ON users (LOWER(email));
CREATE UNIQUE INDEX idx_users_username ON users (LOWER(username));
CREATE INDEX idx_users_role ON users (role);
```

### 5.2 Adding Columns (V2)

```sql
-- V2__add_refresh_tokens.sql

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens (expires_at);
```

### 5.3 Data Migration (V3)

```sql
-- V3__set_default_roles.sql

UPDATE users SET role = 'STUDENT' WHERE role IS NULL;
ALTER TABLE users ALTER COLUMN role SET NOT NULL;
```

### 5.4 Performance Migration (V4)

```sql
-- V4__add_performance_indexes.sql

-- Post search index
CREATE INDEX IF NOT EXISTS idx_posts_content_trgm
    ON posts USING gin (content gin_trgm_ops);

-- Notification unread index
CREATE INDEX IF NOT EXISTS idx_notifications_unread
    ON notifications (user_id, is_read)
    WHERE is_read = false;

-- Concurrent index creation
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_likes_post_count
    ON likes (post_id);
```

## 6. Undo Migrations

```sql
-- U1__undo_create_users_table.sql

DROP TABLE IF EXISTS users;
DROP TYPE IF EXISTS user_role;
```

## 7. Repeatable Migrations

```sql
-- R__user_statistics_view.sql

CREATE OR REPLACE VIEW v_user_statistics AS
SELECT
    u.id,
    u.username,
    u.full_name,
    COUNT(DISTINCT p.id) AS post_count,
    COUNT(DISTINCT f.follower_id) AS follower_count,
    COUNT(DISTINCT f2.following_id) AS following_count
FROM users u
LEFT JOIN posts p ON p.user_id = u.id
LEFT JOIN follows f ON f.following_id = u.id
LEFT JOIN follows f2 ON f2.follower_id = u.id
GROUP BY u.id, u.username, u.full_name;
```

## 8. Migration Commands

```bash
# Run migrations (auto on startup)
mvn flyway:migrate

# Check migration status
mvn flyway:info

# Validate migrations
mvn flyway:validate

# Repair failed migration
mvn flyway:repair

# Baseline existing database
mvn flyway:baseline -Dflyway.baselineVersion=1

# Clean (disabled in production)
mvn flyway:clean -Dflyway.cleanDisabled=false
```

## 9. Best Practices

| Practice | Description |
|----------|-------------|
| **One change per migration** | Each migration should do one logical change |
| **Never modify committed migrations** | Always create new migrations |
| **Test migrations locally** | Use testcontainers for integration tests |
| **Use V for versioned** | U for undo, R for repeatable |
| **Add rollback scripts** | Create undo migrations for critical changes |
| **Index CONCURRENTLY** | Use CONCURRENTLY for production index creation |
| **NO DDL in transactions** | Avoid DDL in transactions for large tables |
| **Backup before migration** | Always backup production before running |

## 10. Testing Migrations

```java
@SpringBootTest
@Testcontainers
class MigrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private DataSource dataSource;

    @Test
    void shouldApplyAllMigrations() {
        Flyway flyway = Flyway.configure()
            .dataSource(dataSource)
            .load();
        flyway.migrate();

        var history = flyway.info().all();
        assertThat(history).isNotEmpty();
        assertThat(history).allMatch(info -> info.getState() == State.SUCCESS);
    }
}
```
