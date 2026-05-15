# RabbitMQ Topics & Queues

## 1. Objective

Document the complete RabbitMQ topology for the Pitaya platform, including exchanges, queues, bindings, and routing keys.

## 2. Broker Architecture

```
                     ┌──────────────────────┐
                     │   RabbitMQ Cluster    │
                     │     pitaya-broker     │
                     └──────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         ▼                    ▼                    ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ pitaya.user  │   │ pitaya.post  │   │ pitaya.group │
   │ (topic)      │   │ (topic)      │   │ (topic)      │
   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
          │                  │                  │
          ▼                  ▼                  ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ queues       │   │ queues       │   │ queues       │
   └──────────────┘   └──────────────┘   └──────────────┘

   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ pitaya.mentor│   │ pitaya.gamif │   │ pitaya.notif │
   │ (topic)      │   │ (topic)      │   │ (topic)      │
   └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
          │                  │                  │
          ▼                  ▼                  ▼
   ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
   │ queues       │   │ queues       │   │ queues       │
   └──────────────┘   └──────────────┘   └──────────────┘
```

## 3. Exchanges

| Exchange Name | Type | Durable | Auto-Delete | Internal |
|--------------|------|---------|-------------|----------|
| pitaya.user | topic | true | false | false |
| pitaya.post | topic | true | false | false |
| pitaya.group | topic | true | false | false |
| pitaya.mentorship | topic | true | false | false |
| pitaya.gamification | topic | true | false | false |
| pitaya.notification | topic | true | false | false |
| pitaya.dlx | direct | true | false | true |
| pitaya.retry | direct | true | false | true |

## 4. Queues

### 4.1 User Exchange Queues

| Queue Name | Routing Key | Consumer | DLQ |
|-----------|-------------|----------|-----|
| queue.user.registered | user.registered | UserService | queue.user.registered.dlq |
| queue.user.profile.updated | user.profile.updated | PostService | queue.user.profile.updated.dlq |

### 4.2 Post Exchange Queues

| Queue Name | Routing Key | Consumer | DLQ |
|-----------|-------------|----------|-----|
| queue.post.created | post.created | GamificationService | queue.post.created.dlq |
| queue.post.created.notification | post.created | NotificationService | queue.post.created.notification.dlq |
| queue.post.comment.added | post.comment.added | NotificationService | queue.post.comment.added.dlq |
| queue.post.liked | post.liked | NotificationService | queue.post.liked.dlq |

### 4.3 Group Exchange Queues

| Queue Name | Routing Key | Consumer | DLQ |
|-----------|-------------|----------|-----|
| queue.group.created | group.created | NotificationService | queue.group.created.dlq |

### 4.4 Mentorship Exchange Queues

| Queue Name | Routing Key | Consumer | DLQ |
|-----------|-------------|----------|-----|
| queue.mentorship.scheduled | mentorship.scheduled | NotificationService | queue.mentorship.scheduled.dlq |
| queue.mentorship.scheduled.gamification | mentorship.scheduled | GamificationService | queue.mentorship.scheduled.gamification.dlq |

### 4.5 Gamification Exchange Queues

| Queue Name | Routing Key | Consumer | DLQ |
|-----------|-------------|----------|-----|
| queue.badge.unlocked | badge.unlocked | NotificationService | queue.badge.unlocked.dlq |

## 5. Binding Configuration

```java
@Configuration
public class RabbitMqBindingConfig {

    // User Exchange
    @Bean
    public Binding userRegisteredBinding() {
        return BindingBuilder.bind(userRegisteredQueue())
            .to(userExchange())
            .with("user.registered");
    }

    // Post Exchange
    @Bean
    public Binding postCreatedNotificationBinding() {
        return BindingBuilder.bind(postCreatedNotificationQueue())
            .to(postExchange())
            .with("post.created");
    }

    // DLQ Bindings
    @Bean
    public Binding userRegisteredDlqBinding() {
        return BindingBuilder.bind(userRegisteredDlq())
            .to(dlxExchange())
            .with("user.registered.dlq");
    }
}
```

## 6. Queue Properties

```yaml
spring:
  rabbitmq:
    template:
      retry:
        enabled: true
        max-attempts: 3
        initial-interval: 2000
        multiplier: 2
        max-interval: 10000
    listener:
      simple:
        retry:
          enabled: true
          max-attempts: 3
          initial-interval: 5000
          multiplier: 2
          max-interval: 30000
        default-requeue-rejected: false
        prefetch: 10
        concurrency: 3
        max-concurrency: 10
```

## 7. Dead Letter Configuration

```java
@Bean
public Queue userRegisteredQueue() {
    return QueueBuilder.durable("queue.user.registered")
        .withArgument("x-dead-letter-exchange", "pitaya.dlx")
        .withArgument("x-dead-letter-routing-key", "user.registered.dlq")
        .withArgument("x-message-ttl", 300000) // 5 minutes
        .withArgument("x-max-priority", 10)
        .build();
}

@Bean
public Queue userRegisteredDlq() {
    return QueueBuilder.durable("queue.user.registered.dlq")
        .withArgument("x-message-ttl", 86400000) // 24 hours
        .build();
}
```

## 8. Event Processing Monitoring

```sql
-- RabbitMQ Management API
GET /api/queues/%2F/queue.user.registered
GET /api/queues/%2F/queue.user.registered.dlq

-- Key metrics
-- queue_depth: messages waiting to process
-- consumer_count: active consumers
-- messages_unacknowledged: in-flight messages
-- publish_rate: messages/second
-- ack_rate: successful processing/second
```

## 9. Retry Strategy

```
Message received
    │
    ▼
Process message
    │
    ├── Success → ACK
    │
    └── Failure → Check retry count in headers
        │
        ├── Retries < 3 → Publish to retry queue with delay
        │                   (5s → 15s → 30s exponential backoff)
        │
        └── Retries >= 3 → Publish to DLQ
                            Alert operations team
```

## 10. Configuration Properties

```yaml
# Application configuration for queue names
rabbitmq:
  exchange:
    user: pitaya.user
    post: pitaya.post
    group: pitaya.group
    mentorship: pitaya.mentorship
    gamification: pitaya.gamification
    notification: pitaya.notification
    dlx: pitaya.dlx
  queue:
    user:
      registered: queue.user.registered
      registered-dlq: queue.user.registered.dlq
      profile-updated: queue.user.profile.updated
    post:
      created: queue.post.created
      created-notification: queue.post.created.notification
      comment-added: queue.post.comment.added
      liked: queue.post.liked
    group:
      created: queue.group.created
    mentorship:
      scheduled: queue.mentorship.scheduled
    badge:
      unlocked: queue.badge.unlocked
```
