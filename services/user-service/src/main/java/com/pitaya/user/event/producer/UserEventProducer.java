package com.pitaya.user.event.producer;

import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.ProfileUpdatedEvent;
import com.pitaya.user.config.RabbitMqConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class UserEventProducer {

    private static final Logger log = LoggerFactory.getLogger(UserEventProducer.class);
    private static final String EVENT_TYPE_PROFILE_UPDATED = "PROFILE_UPDATED";
    private static final String SOURCE = "user-service";

    private final RabbitTemplate rabbitTemplate;

    public UserEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishProfileUpdatedEvent(UUID userId, String displayName, String bio,
                                            String avatarUrl, String location) {
        ProfileUpdatedEvent payload = ProfileUpdatedEvent.builder()
            .userId(userId.toString())
            .displayName(displayName)
            .bio(bio)
            .avatarUrl(avatarUrl)
            .location(location)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            EVENT_TYPE_PROFILE_UPDATED,
            SOURCE,
            userId.toString(),
            payload
        );

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.USER_EXCHANGE,
            RabbitMqConfig.USER_PROFILE_UPDATED_ROUTING_KEY,
            envelope
        );

        log.info("Published PROFILE_UPDATED event for user: {}", userId);
    }
}
