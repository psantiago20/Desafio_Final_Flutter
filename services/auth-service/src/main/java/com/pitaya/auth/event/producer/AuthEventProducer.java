package com.pitaya.auth.event.producer;

import com.pitaya.auth.config.RabbitMqConfig;
import com.pitaya.auth.entity.User;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.UserRegisteredEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
public class AuthEventProducer {

    private static final Logger log = LoggerFactory.getLogger(AuthEventProducer.class);
    private static final String EVENT_TYPE_USER_REGISTERED = "USER_REGISTERED";
    private static final String SOURCE = "auth-service";

    private final RabbitTemplate rabbitTemplate;

    public AuthEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishUserRegisteredEvent(User user) {
        UserRegisteredEvent payload = UserRegisteredEvent.builder()
            .userId(user.getId().toString())
            .email(user.getEmail())
            .username(user.getUsername())
            .fullName(user.getFullName())
            .role(user.getRole().name())
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            EVENT_TYPE_USER_REGISTERED,
            SOURCE,
            user.getId().toString(),
            payload
        );

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.USER_EXCHANGE,
            RabbitMqConfig.USER_REGISTERED_ROUTING_KEY,
            envelope
        );

        log.info("Published USER_REGISTERED event for user: {}", user.getEmail());
    }
}
