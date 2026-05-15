package com.pitaya.user.event.consumer;

import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.UserRegisteredEvent;
import com.pitaya.user.service.ProfileService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class UserEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(UserEventConsumer.class);

    private final ProfileService profileService;

    public UserEventConsumer(ProfileService profileService) {
        this.profileService = profileService;
    }

    @RabbitListener(queues = "${user-service.rabbitmq.queue.user-registered:user.registered}")
    public void handleUserRegistered(EventEnvelope envelope) {
        log.info("Received USER_REGISTERED event: {}", envelope.getEventId());

        try {
            if (envelope.getPayload() instanceof UserRegisteredEvent event) {
                profileService.createProfile(
                    java.util.UUID.fromString(event.getUserId()),
                    event.getFullName(),
                    event.getUsername()
                );
                log.info("Profile created for user: {}", event.getUserId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process USER_REGISTERED event: {}", e.getMessage(), e);
        }
    }
}
