# PostgreSQL Schema

## 1. Objective

Document the complete PostgreSQL schema configuration, including SQL DDL statements, data types, constraints, indexes, and partitioning strategies for each service.

## 2. Global Configuration

```sql
-- PostgreSQL 16 configuration
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '64MB';
ALTER SYSTEM SET default_statistics_target = 100;
ALTER SYSTEM SET random_page_cost = 1.1;
ALTER SYSTEM SET effective_io_concurrency = 200;
ALTER SYSTEM SET work_mem = '32MB';
ALTER SYSTEM SET min_wal_size = '2GB';
ALTER SYSTEM SET max_wal_size = '8GB';
ALTER SYSTEM SET max_worker_processes = 8;
ALTER SYSTEM SET max_parallel_workers_per_gather = 4;
ALTER SYSTEM SET max_parallel_workers = 8;
ALTER SYSTEM SET max_parallel_maintenance_workers = 4;
```

## 3. Common Types (applied to all databases)

```sql
-- Enums
CREATE TYPE user_role AS ENUM ('STUDENT', 'PROFESSOR', 'RESEARCHER', 'MENTOR', 'ADMIN');

CREATE TYPE post_visibility AS ENUM ('PUBLIC', 'FOLLOWERS_ONLY', 'PRIVATE');

CREATE TYPE group_visibility AS ENUM ('PUBLIC', 'PRIVATE', 'RESTRICTED');

CREATE TYPE member_role AS ENUM ('OWNER', 'ADMIN', 'MODERATOR', 'MEMBER');

CREATE TYPE invite_status AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED');

CREATE TYPE material_type AS ENUM ('PDF', 'VIDEO', 'LINK', 'DOCUMENT', 'IMAGE', 'OTHER');

CREATE TYPE mentorship_status AS ENUM ('PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED');

CREATE TYPE session_status AS ENUM ('SCHEDULED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

CREATE TYPE notification_type AS ENUM (
    'LIKE', 'COMMENT', 'REPOST', 'FOLLOW',
    'GROUP_INVITE', 'MENTORSHIP_REQUEST',
    'MENTORSHIP_REMINDER', 'BADGE_UNLOCKED',
    'ACHIEVEMENT', 'SYSTEM'
);

-- UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
```

## 4. Auth Database (auth_db)

```sql
CREATE DATABASE auth_db;
\c auth_db;

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
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_username UNIQUE (username),
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_format CHECK (username ~* '^[a-zA-Z0-9._-]{3,50}$')
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_users_created ON users (created_at DESC);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens (expires_at);

CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_reset_user ON password_reset_tokens (user_id);
CREATE INDEX idx_password_reset_token ON password_reset_tokens (token);
```

## 5. User Database (user_db)

```sql
CREATE DATABASE user_db;
\c user_db;

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    avatar VARCHAR(500),
    banner VARCHAR(500),
    bio TEXT,
    location VARCHAR(100),
    institution VARCHAR(200),
    course VARCHAR(200),
    semester INTEGER,
    research_line VARCHAR(300),
    lattes_url VARCHAR(500),
    orcid VARCHAR(50),
    github_url VARCHAR(500),
    linkedin_url VARCHAR(500),
    profile_complete BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_profiles_user UNIQUE (user_id),
    CONSTRAINT chk_orcid_format CHECK (orcid ~* '^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$'),
    CONSTRAINT chk_semester_range CHECK (semester >= 1 AND semester <= 20)
);

CREATE INDEX idx_profiles_institution ON profiles (institution);
CREATE INDEX idx_profiles_trgm ON profiles USING gin (bio gin_trgm_ops);

CREATE TABLE follows (
    follower_id UUID NOT NULL,
    following_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower ON follows (follower_id);
CREATE INDEX idx_follows_following ON follows (following_id);

CREATE TABLE interests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    icon VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_interests_name UNIQUE (name)
);

CREATE TABLE user_interests (
    user_id UUID NOT NULL,
    interest_id UUID NOT NULL REFERENCES interests(id),
    PRIMARY KEY (user_id, interest_id)
);
```

## 6. Post Database (post_db)

```sql
CREATE DATABASE post_db;
\c post_db;

CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(500),
    visibility post_visibility NOT NULL DEFAULT 'PUBLIC',
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    like_count INTEGER NOT NULL DEFAULT 0,
    comment_count INTEGER NOT NULL DEFAULT 0,
    repost_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_content_length CHECK (char_length(content) <= 5000)
);

CREATE INDEX idx_posts_user ON posts (user_id);
CREATE INDEX idx_posts_created ON posts (created_at DESC);
CREATE INDEX idx_posts_visibility ON posts (visibility);
CREATE INDEX idx_posts_content_trgm ON posts USING gin (content gin_trgm_ops);

-- Partition by month for scalability
CREATE TABLE posts_y2026m05 PARTITION OF posts
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE posts_y2026m06 PARTITION OF posts
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_comment_length CHECK (char_length(content) <= 2000)
);

CREATE INDEX idx_comments_post ON comments (post_id, created_at);
CREATE INDEX idx_comments_user ON comments (user_id);
CREATE INDEX idx_comments_parent ON comments (parent_id);

CREATE TABLE likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_likes_user_post UNIQUE (user_id, post_id)
);

CREATE INDEX idx_likes_post ON likes (post_id);
CREATE INDEX idx_likes_user ON likes (user_id);

CREATE TABLE reposts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    original_post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_reposts_user_post UNIQUE (user_id, original_post_id)
);

CREATE TABLE hashtags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    usage_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_hashtags_name UNIQUE (name)
);

CREATE INDEX idx_hashtags_name ON hashtags (name);
CREATE INDEX idx_hashtags_usage ON hashtags (usage_count DESC);

CREATE TABLE post_hashtags (
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    hashtag_id UUID NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, hashtag_id)
);
```

## 7. Group Database (group_db)

```sql
CREATE DATABASE group_db;
\c group_db;

CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    banner_url VARCHAR(500),
    category VARCHAR(50) NOT NULL,
    visibility group_visibility NOT NULL DEFAULT 'PUBLIC',
    owner_id UUID NOT NULL,
    member_count INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_groups_category ON groups (category);
CREATE INDEX idx_groups_owner ON groups (owner_id);

CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    role member_role NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_group_member UNIQUE (group_id, user_id)
);

CREATE INDEX idx_group_members_group ON group_members (group_id);
CREATE INDEX idx_group_members_user ON group_members (user_id);

CREATE TABLE group_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    invited_by UUID NOT NULL,
    invited_user UUID NOT NULL,
    status invite_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_group_invites_user ON group_invites (invited_user);
CREATE INDEX idx_group_invites_status ON group_invites (status);
```

## 8. Database Migrations (Flyway)

All services use Flyway for migration management.

### Migration File Naming

```
V{version}__{description}.sql
```

Examples:
- `V1__create_users_table.sql`
- `V2__add_profile_fields.sql`
- `V3__add_hashtag_indexes.sql`

### Example Migration

```sql
-- V1__create_users_table.sql
-- Auth Service: Initial user table

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
```

### Rollback Strategy

```sql
-- V1__rollback.sql
DROP TABLE IF EXISTS users;
```

## 9. Backup Strategy

```bash
#!/bin/bash
# Backup all databases
BACKUP_DIR="/backups/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

for db in auth_db user_db post_db group_db library_db mentorship_db gamification_db notification_db; do
    pg_dump -U pitaya -h postgres -Fc $db > $BACKUP_DIR/${db}.dump
    echo "Backed up $db"
done

# Remove backups older than 30 days
find /backups -type d -mtime +30 -exec rm -rf {} \;
```

## 10. Performance Tuning

```sql
-- Analyze all tables
ANALYZE;

-- Update statistics
VACUUM ANALYZE;

-- Common queries
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_user_tables;
SELECT * FROM pg_stat_user_indexes;
SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;
```
