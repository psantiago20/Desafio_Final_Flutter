# ER Diagram

## 1. Objective

Document the complete entity-relationship model for all Pitaya microservices, including table relationships, constraints, indexes, and data integrity rules.

## 2. Database Per Service

Each microservice has its own PostgreSQL database:

```
auth_db          → Auth Service
user_db          → User Service
post_db          → Post Service
group_db         → Group Service
library_db       → Library Service
mentorship_db    → Mentorship Service
gamification_db  → Gamification Service
notification_db  → Notification Service
```

## 3. Auth Service (auth_db)

### Entity: users

```
┌──────────────────────────────────────────────────────────┐
│  users                                                    │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  email           VARCHAR(100)  UNIQUE NOT NULL            │
│  password        VARCHAR(255)  NOT NULL                   │
│  full_name       VARCHAR(150)  NOT NULL                   │
│  username        VARCHAR(50)   UNIQUE NOT NULL            │
│  role            VARCHAR(20)   NOT NULL (ENUM)            │
│  birth_date      DATE          NOT NULL                   │
│  enabled         BOOLEAN       DEFAULT true               │
│  email_verified  BOOLEAN       DEFAULT false              │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- UNIQUE (email)
- UNIQUE (username)
- INDEX idx_users_role (role)
```

### Entity: refresh_tokens

```
┌──────────────────────────────────────────────────────────┐
│  refresh_tokens                                           │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK → users(id)             │
│  token           VARCHAR(500)  NOT NULL                   │
│  expires_at      TIMESTAMP     NOT NULL                   │
│  revoked         BOOLEAN       DEFAULT false              │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_refresh_tokens_user (user_id)
- INDEX idx_refresh_tokens_token (token)
```

### Entity: password_reset_tokens

```
┌──────────────────────────────────────────────────────────┐
│  password_reset_tokens                                    │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK → users(id)             │
│  token           VARCHAR(500)  NOT NULL                   │
│  expires_at      TIMESTAMP     NOT NULL                   │
│  used            BOOLEAN       DEFAULT false              │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘
```

## 4. User Service (user_db)

### Entity: profiles

```
┌──────────────────────────────────────────────────────────┐
│  profiles                                                 │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          UNIQUE NOT NULL             │
│  avatar          VARCHAR(500)                              │
│  banner          VARCHAR(500)                              │
│  bio             TEXT                                      │
│  location        VARCHAR(100)                              │
│  institution     VARCHAR(200)                              │
│  course          VARCHAR(200)                              │
│  semester        INTEGER                                   │
│  research_line   VARCHAR(300)                              │
│  lattes_url      VARCHAR(500)                              │
│  orcid           VARCHAR(50)                               │
│  github_url      VARCHAR(500)                              │
│  linkedin_url    VARCHAR(500)                              │
│  profile_complete BOOLEAN      DEFAULT false               │
│  created_at      TIMESTAMP     NOT NULL                    │
│  updated_at      TIMESTAMP     NOT NULL                    │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- UNIQUE (user_id)
- INDEX idx_profiles_institution (institution)
```

### Entity: follows

```
┌──────────────────────────────────────────────────────────┐
│  follows                                                  │
├──────────────────────────────────────────────────────────┤
│  follower_id     UUID          FK → users(id)             │
│  following_id    UUID          FK → users(id)             │
│  created_at      TIMESTAMP     NOT NULL                   │
│                                                            │
│  PRIMARY KEY (follower_id, following_id)                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- INDEX idx_follows_follower (follower_id)
- INDEX idx_follows_following (following_id)
```

### Entity: interests

```
┌──────────────────────────────────────────────────────────┐
│  interests                                                │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  name            VARCHAR(100)  UNIQUE NOT NULL             │
│  category        VARCHAR(50)   NOT NULL                   │
│  icon            VARCHAR(50)                              │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘
```

### Entity: user_interests

```
┌──────────────────────────────────────────────────────────┐
│  user_interests                                           │
├──────────────────────────────────────────────────────────┤
│  user_id         UUID          FK → users(id)             │
│  interest_id     UUID          FK → interests(id)         │
│                                                            │
│  PRIMARY KEY (user_id, interest_id)                        │
└──────────────────────────────────────────────────────────┘
```

## 5. Post Service (post_db)

### Entity: posts

```
┌──────────────────────────────────────────────────────────┐
│  posts                                                    │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK NOT NULL                │
│  content         TEXT          NOT NULL                   │
│  image_url       VARCHAR(500)                              │
│  visibility      VARCHAR(20)   DEFAULT 'PUBLIC'           │
│  is_pinned       BOOLEAN       DEFAULT false              │
│  like_count      INTEGER       DEFAULT 0                  │
│  comment_count   INTEGER       DEFAULT 0                  │
│  repost_count    INTEGER       DEFAULT 0                  │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_posts_user (user_id)
- INDEX idx_posts_created (created_at DESC)
- INDEX idx_posts_visibility (visibility)
```

### Entity: comments

```
┌──────────────────────────────────────────────────────────┐
│  comments                                                 │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  post_id         UUID          FK → posts(id)             │
│  user_id         UUID          FK NOT NULL                │
│  parent_id       UUID          FK → comments(id)          │
│  content         TEXT          NOT NULL                   │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_comments_post (post_id)
- INDEX idx_comments_user (user_id)
- INDEX idx_comments_parent (parent_id)
```

### Entity: likes

```
┌──────────────────────────────────────────────────────────┐
│  likes                                                    │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK NOT NULL                │
│  post_id         UUID          FK → posts(id)             │
│  created_at      TIMESTAMP     NOT NULL                   │
│                                                            │
│  UNIQUE (user_id, post_id)                                 │
└──────────────────────────────────────────────────────────┘

Indexes:
- UNIQUE (user_id, post_id)
- INDEX idx_likes_post (post_id)
```

### Entity: reposts

```
┌──────────────────────────────────────────────────────────┐
│  reposts                                                  │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK NOT NULL                │
│  original_post_id UUID        FK → posts(id)              │
│  created_at      TIMESTAMP     NOT NULL                   │
│                                                            │
│  UNIQUE (user_id, original_post_id)                        │
└──────────────────────────────────────────────────────────┘
```

### Entity: hashtags

```
┌──────────────────────────────────────────────────────────┐
│  hashtags                                                 │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  name            VARCHAR(100)  UNIQUE NOT NULL             │
│  usage_count     INTEGER       DEFAULT 1                  │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- UNIQUE (name)
- INDEX idx_hashtags_usage (usage_count DESC)
```

### Entity: post_hashtags

```
┌──────────────────────────────────────────────────────────┐
│  post_hashtags                                            │
├──────────────────────────────────────────────────────────┤
│  post_id         UUID          FK → posts(id)             │
│  hashtag_id      UUID          FK → hashtags(id)          │
│                                                            │
│  PRIMARY KEY (post_id, hashtag_id)                         │
└──────────────────────────────────────────────────────────┘
```

## 6. Group Service (group_db)

### Entity: groups

```
┌──────────────────────────────────────────────────────────┐
│  groups                                                   │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  name            VARCHAR(200)  NOT NULL                   │
│  description     TEXT                                      │
│  banner_url      VARCHAR(500)                              │
│  category        VARCHAR(50)   NOT NULL                   │
│  visibility      VARCHAR(20)   DEFAULT 'PUBLIC'           │
│  owner_id        UUID          FK NOT NULL                │
│  member_count    INTEGER       DEFAULT 1                  │
│  is_active       BOOLEAN       DEFAULT true               │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_groups_category (category)
- INDEX idx_groups_owner (owner_id)
```

### Entity: group_members

```
┌──────────────────────────────────────────────────────────┐
│  group_members                                            │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  group_id        UUID          FK → groups(id)            │
│  user_id         UUID          FK NOT NULL                │
│  role            VARCHAR(20)   NOT NULL (ENUM)            │
│  joined_at       TIMESTAMP     NOT NULL                   │
│                                                            │
│  UNIQUE (group_id, user_id)                                │
└──────────────────────────────────────────────────────────┘
```

### Entity: group_invites

```
┌──────────────────────────────────────────────────────────┐
│  group_invites                                            │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  group_id        UUID          FK → groups(id)            │
│  invited_by      UUID          FK NOT NULL                │
│  invited_user    UUID          FK NOT NULL                │
│  status          VARCHAR(20)   DEFAULT 'PENDING'          │
│  created_at      TIMESTAMP     NOT NULL                   │
│  responded_at    TIMESTAMP                                │
└──────────────────────────────────────────────────────────┘
```

## 7. Library Service (library_db)

### Entity: materials

```
┌──────────────────────────────────────────────────────────┐
│  materials                                                │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  title           VARCHAR(300)  NOT NULL                   │
│  description     TEXT                                      │
│  type            VARCHAR(20)   NOT NULL (ENUM)            │
│  url             VARCHAR(500)  NOT NULL                   │
│  file_size       BIGINT                                   │
│  file_type       VARCHAR(50)                               │
│  uploader_id     UUID          FK NOT NULL                │
│  group_id        UUID          FK → groups(id)            │
│  tags            TEXT[]        DEFAULT '{}'               │
│  download_count  INTEGER       DEFAULT 0                  │
│  is_public       BOOLEAN       DEFAULT true               │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_materials_type (type)
- INDEX idx_materials_uploader (uploader_id)
- INDEX idx_materials_group (group_id)
- GIN idx_materials_tags (tags)
```

## 8. Mentorship Service (mentorship_db)

### Entity: mentorships

```
┌──────────────────────────────────────────────────────────┐
│  mentorships                                              │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  mentor_id       UUID          FK NOT NULL                │
│  mentee_id       UUID          FK NOT NULL                │
│  title           VARCHAR(200)  NOT NULL                   │
│  description     TEXT                                      │
│  status          VARCHAR(20)   DEFAULT 'PENDING'          │
│  start_date      DATE                                      │
│  end_date        DATE                                      │
│  max_sessions    INTEGER       DEFAULT 10                 │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_mentorships_mentor (mentor_id)
- INDEX idx_mentorships_mentee (mentee_id)
- INDEX idx_mentorships_status (status)
```

### Entity: mentorship_sessions

```
┌──────────────────────────────────────────────────────────┐
│  mentorship_sessions                                      │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  mentorship_id   UUID          FK → mentorships(id)      │
│  title           VARCHAR(200)                              │
│  description     TEXT                                      │
│  scheduled_at    TIMESTAMP     NOT NULL                   │
│  duration_min    INTEGER       DEFAULT 60                 │
│  status          VARCHAR(20)   DEFAULT 'SCHEDULED'        │
│  meeting_link    VARCHAR(500)                              │
│  mentor_notes    TEXT                                      │
│  mentee_feedback TEXT                                      │
│  rating          INTEGER       CHECK (1-5)                │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘
```

## 9. Gamification Service (gamification_db)

### Entity: user_gamification

```
┌──────────────────────────────────────────────────────────┐
│  user_gamification                                        │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          UNIQUE NOT NULL            │
│  xp_points       INTEGER       DEFAULT 0                  │
│  level           INTEGER       DEFAULT 1                  │
│  created_at      TIMESTAMP     NOT NULL                   │
│  updated_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- UNIQUE (user_id)
- INDEX idx_gamification_xp (xp_points DESC)
```

### Entity: badges

```
┌──────────────────────────────────────────────────────────┐
│  badges                                                   │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  name            VARCHAR(100)  UNIQUE NOT NULL             │
│  description     TEXT                                      │
│  icon_url        VARCHAR(500)                              │
│  category        VARCHAR(50)   NOT NULL                   │
│  xp_required     INTEGER       DEFAULT 0                  │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘
```

### Entity: user_badges

```
┌──────────────────────────────────────────────────────────┐
│  user_badges                                              │
├──────────────────────────────────────────────────────────┤
│  user_id         UUID          FK NOT NULL                │
│  badge_id        UUID          FK → badges(id)            │
│  unlocked_at     TIMESTAMP     NOT NULL                   │
│                                                            │
│  PRIMARY KEY (user_id, badge_id)                           │
└──────────────────────────────────────────────────────────┘
```

## 10. Notification Service (notification_db)

### Entity: notifications

```
┌──────────────────────────────────────────────────────────┐
│  notifications                                            │
├──────────────────────────────────────────────────────────┤
│  id              UUID          PK                         │
│  user_id         UUID          FK NOT NULL                │
│  type            VARCHAR(50)   NOT NULL                   │
│  title           VARCHAR(200)  NOT NULL                   │
│  message         TEXT          NOT NULL                   │
│  reference_id    UUID                                      │
│  reference_type  VARCHAR(50)                               │
│  is_read         BOOLEAN       DEFAULT false              │
│  created_at      TIMESTAMP     NOT NULL                   │
└──────────────────────────────────────────────────────────┘

Indexes:
- PRIMARY KEY (id)
- INDEX idx_notifications_user (user_id)
- INDEX idx_notifications_unread (user_id, is_read)
```

## 11. Relationships Summary

```
users 1──N follows (follower)
users 1──N follows (following)
users 1──1 profiles
users N──M interests (via user_interests)
users 1──N posts
users 1──N comments
users N──M posts (via likes)
users N──M posts (via reposts)
groups N──M users (via group_members)
groups 1──N group_invites
users 1──N materials
users 1──N mentorships (mentor)
users 1──N mentorships (mentee)
mentorships 1──N mentorship_sessions
users 1──1 user_gamification
users N──M badges (via user_badges)
users 1──N notifications
posts N──M hashtags (via post_hashtags)
```
