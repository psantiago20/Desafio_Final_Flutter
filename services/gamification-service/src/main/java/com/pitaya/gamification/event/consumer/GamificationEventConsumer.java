package com.pitaya.gamification.event.consumer;

import com.pitaya.gamification.service.EventHandlerService;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.CommentAddedEvent;
import com.pitaya.shared.event.events.MentorshipScheduledEvent;
import com.pitaya.shared.event.events.PostCreatedEvent;
import com.pitaya.shared.event.events.PostLikedEvent;
import com.pitaya.shared.event.events.UserRegisteredEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class GamificationEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(GamificationEventConsumer.class);

    private final EventHandlerService eventHandlerService;

    public GamificationEventConsumer(EventHandlerService eventHandlerService) {
        this.eventHandlerService = eventHandlerService;
    }

    @RabbitListener(queues = "${gamification-service.rabbitmq.queue.post-created:gamification.post.created}")
    public void handlePostCreated(EventEnvelope envelope) {
        log.info("Received POST_CREATED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof PostCreatedEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                eventHandlerService.handlePostCreated(userId, event.getPostId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process POST_CREATED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${gamification-service.rabbitmq.queue.comment-added:gamification.post.comment.added}")
    public void handleCommentAdded(EventEnvelope envelope) {
        log.info("Received COMMENT_ADDED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof CommentAddedEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                eventHandlerService.handleCommentAdded(userId, event.getCommentId(), event.getPostId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process COMMENT_ADDED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${gamification-service.rabbitmq.queue.post-liked:gamification.post.liked}")
    public void handlePostLiked(EventEnvelope envelope) {
        log.info("Received POST_LIKED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof PostLikedEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                eventHandlerService.handlePostLiked(userId, event.getPostId(), event.getPostAuthorId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process POST_LIKED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${gamification-service.rabbitmq.queue.user-registered:gamification.user.registered}")
    public void handleUserRegistered(EventEnvelope envelope) {
        log.info("Received USER_REGISTERED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof UserRegisteredEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                eventHandlerService.handleUserRegistered(userId, event.getEmail(),
                    event.getUsername(), event.getFullName());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process USER_REGISTERED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${gamification-service.rabbitmq.queue.mentorship-scheduled:gamification.mentorship.scheduled}")
    public void handleMentorshipScheduled(EventEnvelope envelope) {
        log.info("Received MENTORSHIP_SCHEDULED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof MentorshipScheduledEvent event) {
                UUID mentorId = UUID.fromString(event.getMentorId());
                UUID menteeId = UUID.fromString(event.getMenteeId());
                eventHandlerService.handleMentorshipScheduled(mentorId, menteeId, event.getMentorshipId());
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process MENTORSHIP_SCHEDULED event: {}", e.getMessage(), e);
        }
    }
}
