# Event-Driven Architecture

## 1. Objective

Define the event-driven communication backbone of the Pitaya platform, enabling asynchronous, decoupled, and resilient service interactions.

## 2. Responsibilities

- Define event schema and contract standards
- Document producer/consumer relationships
- Establish routing and delivery guarantees
- Define error handling and dead-letter strategies

## 3. Architecture Overview

```
                    ┌───────────────────┐
                    │   Event Producer   │
                    │   (Service A)      │
                    └─────────┬─────────┘
                              │ publish
                              ▼
                    ┌───────────────────┐
                    │   Message Broker   │
                    │  RabbitMQ / Kafka  │
                    └─────────┬─────────┘
                              │ deliver
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
            ┌──────────────┐  ┌──────────────┐
            │  Consumer 1  │  │  Consumer 2  │
            │  (Service B) │  │  (Service C) │
            └──────────────┘  └──────────────┘
```

## 4. Broker Selection: RabbitMQ + Kafka

| Feature | RabbitMQ | Kafka |
|---------|----------|-------|
| Primary Use | Business events, notifications | Analytics, high-throughput events |
| Routing | Exchange/Topic flexible | Topic-based |
| Delivery | Complex routing, ACK-based | Log-based, replayable |
| Retention | Until consumed | Configurable retention period |
| Ordering | Per queue | Per partition |
| Persistence | Yes | Yes |

**Decision**: Use RabbitMQ as primary broker for business events. Use Kafka for gamification analytics and event sourcing.

## 5. Event Contract Standards

### 5.1 Event Envelope

Every event must follow this structure:

```json
{
  "eventId": "uuid-v4",
  "eventType": "USER_REGISTERED",
  "source": "pitaya-auth-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "correlationId": "client-trace-id",
  "userId": "user-uuid",
  "payload": {}
}
```

### 5.2 Event Type Naming

`{ENTITY}_{ACTION}` in UPPER_SNAKE_CASE:
- `USER_REGISTERED`
- `PROFILE_UPDATED`
- `POST_CREATED`
- `COMMENT_ADDED`
- `POST_LIKED`
- `GROUP_CREATED`
- `MENTORSHIP_SCHEDULED`
- `BADGE_UNLOCKED`
- `NOTIFICATION_SENT`

## 6. Event Catalog

### 6.1 USER_REGISTERED

**Producer**: Auth Service
**Consumers**: User Service, Gamification Service, Notification Service
**Exchange**: `pitaya.user`
**Routing Key**: `user.registered`

```json
{
  "eventId": "550e8400-e29b-41d4-a716-446655440000",
  "eventType": "USER_REGISTERED",
  "source": "pitaya-auth-service",
  "timestamp": "2026-05-14T12:00:00Z",
  "version": 1,
  "userId": "a1b2c3d4-...",
  "payload": {
    "email": "user@university.edu",
    "role": "STUDENT",
    "fullName": "Maria Silva"
  }
}
```

### 6.2 PROFILE_UPDATED

**Producer**: User Service
**Consumers**: Post Service, Gamification Service, Notification Service
**Exchange**: `pitaya.user`
**Routing Key**: `user.profile.updated`

```json
{
  "eventId": "660e8400-e29b-41d4-a716-446655440001",
  "eventType": "PROFILE_UPDATED",
  "source": "pitaya-user-service",
  "timestamp": "2026-05-14T12:05:00Z",
  "version": 1,
  "userId": "a1b2c3d4-...",
  "payload": {
    "bio": "PhD candidate in Computer Science",
    "interests": ["AI", "Machine Learning"],
    "institution": "USP"
  }
}
```

### 6.3 POST_CREATED

**Producer**: Post Service
**Consumers**: Gamification Service, Notification Service
**Exchange**: `pitaya.post`
**Routing Key**: `post.created`

```json
{
  "eventId": "770e8400-e29b-41d4-a716-446655440002",
  "eventType": "POST_CREATED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:10:00Z",
  "version": 1,
  "userId": "a1b2c3d4-...",
  "payload": {
    "postId": "p12345",
    "content": "New paper published on #NLP",
    "hashtags": ["NLP"],
    "visibility": "PUBLIC"
  }
}
```

### 6.4 COMMENT_ADDED

**Producer**: Post Service
**Consumers**: Notification Service, Gamification Service
**Exchange**: `pitaya.post`
**Routing Key**: `post.comment.added`

```json
{
  "eventId": "880e8400-e29b-41d4-a716-446655440003",
  "eventType": "COMMENT_ADDED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:15:00Z",
  "version": 1,
  "userId": "b2c3d4e5-...",
  "payload": {
    "postId": "p12345",
    "commentId": "c67890",
    "content": "Great research!"
  }
}
```

### 6.5 POST_LIKED

**Producer**: Post Service
**Consumers**: Notification Service, Gamification Service
**Exchange**: `pitaya.post`
**Routing Key**: `post.liked`

```json
{
  "eventId": "990e8400-e29b-41d4-a716-446655440004",
  "eventType": "POST_LIKED",
  "source": "pitaya-post-service",
  "timestamp": "2026-05-14T12:20:00Z",
  "version": 1,
  "userId": "c3d4e5f6-...",
  "payload": {
    "postId": "p12345",
    "likerId": "c3d4e5f6-..."
  }
}
```

### 6.6 GROUP_CREATED

**Producer**: Group Service
**Consumers**: Notification Service
**Exchange**: `pitaya.group`
**Routing Key**: `group.created`

```json
{
  "eventId": "aa0e8400-e29b-41d4-a716-446655440005",
  "eventType": "GROUP_CREATED",
  "source": "pitaya-group-service",
  "timestamp": "2026-05-14T12:25:00Z",
  "version": 1,
  "userId": "d4e5f6a7-...",
  "payload": {
    "groupId": "g11111",
    "name": "AI Study Group",
    "category": "TECHNOLOGY"
  }
}
```

### 6.7 MENTORSHIP_SCHEDULED

**Producer**: Mentorship Service
**Consumers**: Notification Service, Gamification Service
**Exchange**: `pitaya.mentorship`
**Routing Key**: `mentorship.scheduled`

```json
{
  "eventId": "bb0e8400-e29b-41d4-a716-446655440006",
  "eventType": "MENTORSHIP_SCHEDULED",
  "source": "pitaya-mentorship-service",
  "timestamp": "2026-05-14T12:30:00Z",
  "version": 1,
  "userId": "e5f6a7b8-...",
  "payload": {
    "mentorshipId": "m22222",
    "mentorId": "f6a7b8c9-...",
    "menteeId": "a1b2c3d4-...",
    "scheduledAt": "2026-05-20T14:00:00Z"
  }
}
```

### 6.8 BADGE_UNLOCKED

**Producer**: Gamification Service
**Consumers**: Notification Service
**Exchange**: `pitaya.gamification`
**Routing Key**: `badge.unlocked`

```json
{
  "eventId": "cc0e8400-e29b-41d4-a716-446655440007",
  "eventType": "BADGE_UNLOCKED",
  "source": "pitaya-gamification-service",
  "timestamp": "2026-05-14T12:35:00Z",
  "version": 1,
  "userId": "a1b2c3d4-...",
  "payload": {
    "badgeId": "b33333",
    "badgeName": "First Post",
    "category": "SOCIAL"
  }
}
```

### 6.9 NOTIFICATION_SENT

**Producer**: Notification Service
**Consumers**: (Logging, Analytics future)
**Exchange**: `pitaya.notification`
**Routing Key**: `notification.sent`

```json
{
  "eventId": "dd0e8400-e29b-41d4-a716-446655440008",
  "eventType": "NOTIFICATION_SENT",
  "source": "pitaya-notification-service",
  "timestamp": "2026-05-14T12:40:00Z",
  "version": 1,
  "userId": "a1b2c3d4-...",
  "payload": {
    "notificationId": "n44444",
    "type": "LIKE",
    "message": "João liked your post"
  }
}
```

## 7. RabbitMQ Configuration

### 7.1 Exchanges

| Exchange Name | Type | Durable |
|--------------|------|---------|
| `pitaya.user` | topic | true |
| `pitaya.post` | topic | true |
| `pitaya.group` | topic | true |
| `pitaya.mentorship` | topic | true |
| `pitaya.gamification` | topic | true |
| `pitaya.notification` | topic | true |
| `pitaya.dlx` | direct | true |

### 7.2 Dead Letter Strategy

Each queue has a corresponding DLQ:

```
Queue: pitaya.user.registered
DLQ:   pitaya.user.registered.dlq
DLX:   pitaya.dlx
Retry: 3 attempts with 5s, 15s, 30s delays
```

## 8. Consumer Implementation

```java
@Component
@Slf4j
public class UserRegisteredConsumer {

    @RabbitListener(queues = "${rabbitmq.queue.user.registered}")
    public void handleUserRegistered(UserRegisteredEvent event) {
        log.info("Processing USER_REGISTERED: {}", event.getUserId());
        try {
            userService.createProfile(event);
        } catch (Exception e) {
            log.error("Failed to process event: {}", event.getEventId(), e);
            throw new AmqpRejectAndDontRequeueException(e);
        }
    }
}
```

## 9. Producer Implementation

```java
@Service
@Slf4j
public class AuthEventProducer {

    private final RabbitTemplate rabbitTemplate;

    public void publishUserRegistered(User user) {
        var event = EventEnvelope.<UserRegisteredPayload>builder()
            .eventId(UUID.randomUUID().toString())
            .eventType("USER_REGISTERED")
            .source("pitaya-auth-service")
            .timestamp(Instant.now())
            .version(1)
            .userId(user.getId().toString())
            .payload(new UserRegisteredPayload(user.getEmail(), user.getRole(), user.getFullName()))
            .build();

        rabbitTemplate.convertAndSend("pitaya.user", "user.registered", event);
        log.info("Published USER_REGISTERED for user: {}", user.getId());
    }
}
```

## 10. Retry and Error Handling

### 10.1 Retry Strategy

| Attempt | Delay | Action |
|---------|-------|--------|
| 1 | 5s | Retry |
| 2 | 15s | Retry |
| 3 | 30s | Send to DLQ |

### 10.2 Unprocessable Events

Events that fail after max retries are sent to DLQ with:
- Original payload preserved
- Error details in headers
- Stack trace in headers
- Alert triggered for manual inspection

## 11. Best Practices

1. **Idempotency**: All consumers must handle duplicate events (use eventId deduplication)
2. **Ordering**: Use RabbitMQ single queue for ordered events per entity
3. **Versioning**: Events have version field; consumers handle multiple versions
4. **Validation**: Validate event payload before processing
5. **Monitoring**: Track event processing time, success rate, queue depth
6. **Security**: Events carry userId for audit trail
7. **Schema Registry**: Maintain event schemas centrally (future consideration)
