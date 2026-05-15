package com.pitaya.notification.event.producer;

import com.pitaya.notification.config.RabbitMqConfig;
import com.pitaya.notification.dto.response.NotificationResponse;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.NotificationSentEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@Component
public class NotificationEventProducer {

    private static final Logger log = LoggerFactory.getLogger(NotificationEventProducer.class);
    private static final String SOURCE = "notification-service";

    private final RabbitTemplate rabbitTemplate;

    public NotificationEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishNotificationSent(NotificationResponse notification) {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("type", notification.getType().name());
        metadata.put("referenceId", notification.getReferenceId() != null
            ? notification.getReferenceId().toString() : null);
        metadata.put("referenceType", notification.getReferenceType());

        NotificationSentEvent payload = NotificationSentEvent.builder()
            .notificationId(notification.getId().toString())
            .userId(notification.getUserId().toString())
            .type(notification.getType().name())
            .title(notification.getTitle())
            .body(notification.getMessage())
            .metadata(metadata)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "NOTIFICATION_SENT", SOURCE, notification.getUserId().toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.NOTIFICATION_EXCHANGE,
            RabbitMqConfig.NOTIFICATION_SENT_ROUTING_KEY,
            envelope);

        log.info("Published NOTIFICATION_SENT event for notification: {}", notification.getId());
    }
}
