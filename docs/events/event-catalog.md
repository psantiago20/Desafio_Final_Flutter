# Event Catalog

## 1. Objective

Document the complete catalog of system events in the Pitaya platform, including event types, producers, consumers, triggers, and business context.

## 2. Event Overview

| # | Event Type | Producer | Consumers | Trigger | Priority |
|---|-----------|----------|-----------|---------|----------|
| 1 | USER_REGISTERED | Auth Service | User, Gamification, Notification | New user registration | High |
| 2 | PROFILE_UPDATED | User Service | Post, Gamification, Notification | Profile edit | Medium |
| 3 | POST_CREATED | Post Service | Gamification, Notification | New post | High |
| 4 | COMMENT_ADDED | Post Service | Notification, Gamification | New comment | Medium |
| 5 | POST_LIKED | Post Service | Notification, Gamification | Like action | Low |
| 6 | GROUP_CREATED | Group Service | Notification | Group creation | Medium |
| 7 | MENTORSHIP_SCHEDULED | Mentorship Service | Notification, Gamification | Session scheduled | High |
| 8 | BADGE_UNLOCKED | Gamification Service | Notification | Badge awarded | Medium |
| 9 | NOTIFICATION_SENT | Notification Service | — (logging) | Notification delivery | Low |

## 3. Event Details

### 3.1 USER_REGISTERED

**Business Context**: A new user has completed registration and needs initial setup.

**Trigger**: POST /api/v1/auth/register

**Importance**: Critical — triggers profile creation, welcome badge, welcome notification.

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "USER_REGISTERED",
  "source": "pitaya-auth-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "email": "string",
    "fullName": "string",
    "username": "string",
    "role": "STUDENT | PROFESSOR | RESEARCHER | MENTOR | ADMIN"
  }
}
```

**Consumer Actions:**
- User Service: Create profile record
- Gamification Service: Award "Welcome" badge (100 XP)
- Notification Service: Send welcome notification

---

### 3.2 PROFILE_UPDATED

**Business Context**: User has updated their academic or social profile information.

**Trigger**: PUT /api/v1/users/{id}/profile

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "PROFILE_UPDATED",
  "source": "pitaya-user-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "changes": {
      "bio": "string|null",
      "institution": "string|null",
      "course": "string|null",
      "semester": "number|null",
      "interests": ["string"]
    }
  }
}
```

**Consumer Actions:**
- Gamification Service: Check for profile completion badge
- Notification Service: Notify if profile is now complete

---

### 3.3 POST_CREATED

**Business Context**: A user has published a new post to the platform.

**Trigger**: POST /api/v1/posts

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "POST_CREATED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "postId": "uuid",
    "content": "string",
    "hashtags": ["string"],
    "visibility": "PUBLIC | FOLLOWERS_ONLY | PRIVATE"
  }
}
```

**Consumer Actions:**
- Gamification Service: Award "First Post" badge if first post; add XP
- Notification Service: Notify followers (if visibility = PUBLIC)

---

### 3.4 COMMENT_ADDED

**Business Context**: A user has commented on a post.

**Trigger**: POST /api/v1/posts/{id}/comments

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "COMMENT_ADDED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "postId": "uuid",
    "commentId": "uuid",
    "postAuthorId": "uuid",
    "content": "string",
    "parentCommentId": "uuid|null"
  }
}
```

**Consumer Actions:**
- Notification Service: Notify post author; notify parent comment author if reply
- Gamification Service: Add XP for commenting

---

### 3.5 POST_LIKED

**Business Context**: A user has liked a post.

**Trigger**: POST /api/v1/posts/{id}/like

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "POST_LIKED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "postId": "uuid",
    "likerId": "uuid",
    "postAuthorId": "uuid"
  }
}
```

**Consumer Actions:**
- Notification Service: Notify post author of new like
- Gamification Service: Add XP for liking

---

### 3.6 GROUP_CREATED

**Business Context**: A new study group has been created.

**Trigger**: POST /api/v1/groups

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "GROUP_CREATED",
  "source": "pitaya-group-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "groupId": "uuid",
    "name": "string",
    "description": "string",
    "category": "string",
    "visibility": "PUBLIC | PRIVATE | RESTRICTED"
  }
}
```

**Consumer Actions:**
- Notification Service: Notify relevant users based on interests

---

### 3.7 MENTORSHIP_SCHEDULED

**Business Context**: A mentorship session has been scheduled.

**Trigger**: POST /api/v1/mentorships/{id}/sessions

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "MENTORSHIP_SCHEDULED",
  "source": "pitaya-mentorship-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "mentorshipId": "uuid",
    "sessionId": "uuid",
    "mentorId": "uuid",
    "menteeId": "uuid",
    "scheduledAt": "2026-05-20T14:00:00Z",
    "durationMinutes": 60
  }
}
```

**Consumer Actions:**
- Notification Service: Notify both mentor and mentee
- Gamification Service: Award scheduling XP

---

### 3.8 BADGE_UNLOCKED

**Business Context**: A user has unlocked a new badge or achievement.

**Trigger**: Internal (Gamification Service check)

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "BADGE_UNLOCKED",
  "source": "pitaya-gamification-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "badgeId": "uuid",
    "badgeName": "string",
    "badgeCategory": "SOCIAL | ACADEMIC | CONTRIBUTION | MILESTONE",
    "badgeIcon": "string",
    "xpAwarded": 100
  }
}
```

**Consumer Actions:**
- Notification Service: Send congratulatory notification

---

### 3.9 NOTIFICATION_SENT

**Business Context**: A notification has been sent to a user.

**Trigger**: Internal (Notification Service)

**Schema Version**: 1

```json
{
  "eventId": "uuid",
  "eventType": "NOTIFICATION_SENT",
  "source": "pitaya-notification-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "uuid",
  "payload": {
    "notificationId": "uuid",
    "type": "LIKE | COMMENT | FOLLOW | GROUP_INVITE | BADGE | SYSTEM",
    "title": "string",
    "message": "string",
    "channel": "IN_APP | EMAIL | PUSH"
  }
}
```

**Consumer Actions:**
- Log for analytics
- Future: Email/Push integration

## 4. Event Processing Guarantees

| Guarantee | Implementation |
|-----------|---------------|
| At-least-once delivery | RabbitMQ acknowledgments |
| Ordering per entity | Single queue per entity type |
| Idempotency | Event ID deduplication (Redis set, 24h TTL) |
| Error handling | 3 retries → Dead Letter Queue |
| Monitoring | Track processing time, success rate |

## 5. Event Versioning Strategy

- Events have a `version` field (integer, starting at 1)
- Consumers must handle current version
- New fields are additive (backward compatible)
- Breaking changes increment the version
- Multiple versions can coexist during migration
