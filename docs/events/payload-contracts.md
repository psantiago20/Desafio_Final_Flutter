# Payload Contracts

## 1. Objective

Define the complete JSON schema contracts for all event payloads in the Pitaya platform, ensuring type safety and interoperability between services.

## 2. Event Envelope Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "EventEnvelope",
  "type": "object",
  "required": [
    "eventId", "eventType", "source",
    "timestamp", "version", "userId", "payload"
  ],
  "properties": {
    "eventId": {
      "type": "string",
      "format": "uuid",
      "description": "Unique event identifier for deduplication"
    },
    "eventType": {
      "type": "string",
      "pattern": "^[A-Z_]+$",
      "description": "Event type in UPPER_SNAKE_CASE"
    },
    "source": {
      "type": "string",
      "pattern": "^pitaya-[a-z-]+-service$",
      "description": "Service that produced the event"
    },
    "timestamp": {
      "type": "string",
      "format": "date-time",
      "description": "ISO 8601 UTC timestamp"
    },
    "version": {
      "type": "integer",
      "minimum": 1,
      "description": "Payload schema version"
    },
    "correlationId": {
      "type": "string",
      "description": "Client trace ID for request correlation"
    },
    "userId": {
      "type": "string",
      "format": "uuid",
      "description": "User who triggered the event"
    },
    "payload": {
      "type": "object",
      "description": "Event-specific payload"
    }
  }
}
```

## 3. Event Payload Schemas

### 3.1 UserRegisteredPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "UserRegisteredPayload",
  "version": 1,
  "type": "object",
  "required": ["email", "fullName", "username", "role"],
  "properties": {
    "email": {
      "type": "string",
      "format": "email",
      "maxLength": 100,
      "example": "maria.silva@usp.br"
    },
    "fullName": {
      "type": "string",
      "maxLength": 150,
      "example": "Maria Silva"
    },
    "username": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9._-]{3,50}$",
      "example": "maria.silva"
    },
    "role": {
      "type": "string",
      "enum": ["STUDENT", "PROFESSOR", "RESEARCHER", "MENTOR", "ADMIN"],
      "example": "STUDENT"
    }
  }
}
```

### 3.2 ProfileUpdatedPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ProfileUpdatedPayload",
  "version": 1,
  "type": "object",
  "required": ["changes"],
  "properties": {
    "changes": {
      "type": "object",
      "properties": {
        "bio": { "type": ["string", "null"], "maxLength": 500 },
        "institution": { "type": ["string", "null"], "maxLength": 200 },
        "course": { "type": ["string", "null"], "maxLength": 200 },
        "semester": { "type": ["integer", "null"], "minimum": 1, "maximum": 20 },
        "interests": {
          "type": "array",
          "items": { "type": "string", "maxLength": 100 }
        }
      }
    }
  },
  "example": {
    "changes": {
      "bio": "PhD candidate in Computer Science at USP",
      "institution": "Universidade de São Paulo",
      "course": "Computer Science",
      "semester": 8,
      "interests": ["AI", "Machine Learning", "NLP"]
    }
  }
}
```

### 3.3 PostCreatedPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PostCreatedPayload",
  "version": 1,
  "type": "object",
  "required": ["postId", "content", "hashtags"],
  "properties": {
    "postId": {
      "type": "string",
      "format": "uuid"
    },
    "content": {
      "type": "string",
      "maxLength": 5000,
      "example": "Acabei de publicar meu novo artigo sobre #MachineLearning! Link na bio."
    },
    "hashtags": {
      "type": "array",
      "items": {
        "type": "string",
        "pattern": "^[A-Za-zÀ-ÿ0-9]+$"
      },
      "example": ["MachineLearning", "AI"]
    },
    "visibility": {
      "type": "string",
      "enum": ["PUBLIC", "FOLLOWERS_ONLY", "PRIVATE"],
      "default": "PUBLIC"
    }
  }
}
```

### 3.4 CommentAddedPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "CommentAddedPayload",
  "version": 1,
  "type": "object",
  "required": ["postId", "commentId", "postAuthorId", "content"],
  "properties": {
    "postId": { "type": "string", "format": "uuid" },
    "commentId": { "type": "string", "format": "uuid" },
    "postAuthorId": { "type": "string", "format": "uuid" },
    "content": { "type": "string", "maxLength": 2000 },
    "parentCommentId": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Set if this is a reply to another comment"
    }
  }
}
```

### 3.5 PostLikedPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "PostLikedPayload",
  "version": 1,
  "type": "object",
  "required": ["postId", "likerId", "postAuthorId"],
  "properties": {
    "postId": { "type": "string", "format": "uuid" },
    "likerId": { "type": "string", "format": "uuid" },
    "postAuthorId": { "type": "string", "format": "uuid" }
  }
}
```

### 3.6 BadgeUnlockedPayload

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BadgeUnlockedPayload",
  "version": 1,
  "type": "object",
  "required": ["badgeId", "badgeName", "badgeCategory", "xpAwarded"],
  "properties": {
    "badgeId": { "type": "string", "format": "uuid" },
    "badgeName": { "type": "string", "example": "First Post" },
    "badgeCategory": {
      "type": "string",
      "enum": ["ACADEMIC", "SOCIAL", "CONTRIBUTION", "MILESTONE"]
    },
    "badgeIcon": { "type": "string", "description": "URL or emoji" },
    "xpAwarded": { "type": "integer", "minimum": 0, "example": 100 }
  }
}
```

## 4. Java Class Contracts

### 4.1 Event Envelope

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventEnvelope<T> {
    @NotNull
    private String eventId;

    @NotNull
    private String eventType;

    @NotNull
    private String source;

    @NotNull
    private Instant timestamp;

    @Min(1)
    private int version;

    private String correlationId;

    @NotNull
    private String userId;

    @NotNull
    private T payload;
}
```

### 4.2 Event Interfaces

```java
public interface BaseEvent {
    String getEventId();
    String getEventType();
    String getSource();
    Instant getTimestamp();
    int getVersion();
    String getUserId();
}

public interface EventPublisher<T extends BaseEvent> {
    void publish(T event);
}

public interface EventConsumer<T extends BaseEvent> {
    void consume(T event);
}
```

## 5. Payload Validation

```java
@Component
public class EventValidator {

    private static final Set<String> VALID_EVENT_TYPES = Set.of(
        "USER_REGISTERED", "PROFILE_UPDATED", "POST_CREATED",
        "COMMENT_ADDED", "POST_LIKED", "GROUP_CREATED",
        "MENTORSHIP_SCHEDULED", "BADGE_UNLOCKED", "NOTIFICATION_SENT"
    );

    public void validate(EventEnvelope<?> event) {
        Assert.notNull(event.getEventId(), "eventId is required");
        Assert.notNull(event.getEventType(), "eventType is required");
        Assert.isTrue(VALID_EVENT_TYPES.contains(event.getEventType()),
            "Invalid event type: " + event.getEventType());
        Assert.notNull(event.getUserId(), "userId is required");
        Assert.notNull(event.getTimestamp(), "timestamp is required");
        Assert.isTrue(event.getVersion() >= 1, "version must be >= 1");
    }
}
```

## 6. Schema Registry (Future)

The schema registry will store all event schemas with versioning:

```
GET /api/schemas/USER_REGISTERED/v1
GET /api/schemas/USER_REGISTERED/v2
GET /api/schemas
```
