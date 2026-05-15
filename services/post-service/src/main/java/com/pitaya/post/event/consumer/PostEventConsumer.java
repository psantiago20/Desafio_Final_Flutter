package com.pitaya.post.event.consumer;

import com.pitaya.post.service.TimelineService;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.ProfileUpdatedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class PostEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(PostEventConsumer.class);

    private final TimelineService timelineService;

    public PostEventConsumer(TimelineService timelineService) {
        this.timelineService = timelineService;
    }

    @RabbitListener(queues = "${post-service.rabbitmq.queue.profile-updated:user.profile.updated}")
    public void handleProfileUpdated(EventEnvelope envelope) {
        log.info("Received PROFILE_UPDATED event: {}", envelope.getEventId());

        try {
            if (envelope.getPayload() instanceof ProfileUpdatedEvent event) {
                timelineService.evictTimelineCache(java.util.UUID.fromString(event.getUserId()));
                log.info("Timeline cache evicted for user: {}", event.getUserId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process PROFILE_UPDATED event: {}", e.getMessage(), e);
        }
    }
}
