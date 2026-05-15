package com.pitaya.notification.event.consumer;

import com.pitaya.notification.entity.NotificationType;
import com.pitaya.notification.service.NotificationService;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.BadgeUnlockedEvent;
import com.pitaya.shared.event.events.CommentAddedEvent;
import com.pitaya.shared.event.events.GroupCreatedEvent;
import com.pitaya.shared.event.events.MentorshipScheduledEvent;
import com.pitaya.shared.event.events.PostCreatedEvent;
import com.pitaya.shared.event.events.PostLikedEvent;
import com.pitaya.shared.event.events.ProfileUpdatedEvent;
import com.pitaya.shared.event.events.UserRegisteredEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class NotificationEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificationEventConsumer.class);

    private final NotificationService notificationService;

    public NotificationEventConsumer(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.post-liked:notification.post.liked}")
    public void handlePostLiked(EventEnvelope envelope) {
        log.info("Received POST_LIKED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof PostLikedEvent event) {
                UUID postAuthorId = UUID.fromString(event.getPostAuthorId());
                UUID likerId = UUID.fromString(event.getUserId());
                if (!postAuthorId.equals(likerId)) {
                    notificationService.createNotification(
                        postAuthorId,
                        NotificationType.LIKE,
                        "New Like",
                        "User " + likerId + " liked your post",
                        UUID.fromString(event.getPostId()),
                        "POST"
                    );
                }
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process POST_LIKED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.comment-added:notification.post.comment.added}")
    public void handleCommentAdded(EventEnvelope envelope) {
        log.info("Received COMMENT_ADDED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof CommentAddedEvent event) {
                String content = event.getContent();
                String preview = content.length() > 50 ? content.substring(0, 50) + "..." : content;
                notificationService.createNotification(
                    UUID.fromString(event.getUserId()),
                    NotificationType.COMMENT,
                    "New Comment",
                    "User commented: " + preview,
                    UUID.fromString(event.getPostId()),
                    "POST"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process COMMENT_ADDED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.post-created:notification.post.created}")
    public void handlePostCreated(EventEnvelope envelope) {
        log.info("Received POST_CREATED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof PostCreatedEvent event) {
                UUID authorId = UUID.fromString(event.getUserId());
                String preview = event.getContent() != null && event.getContent().length() > 80
                    ? event.getContent().substring(0, 80) + "..."
                    : event.getContent();
                notificationService.createNotification(
                    authorId,
                    NotificationType.SYSTEM,
                    "Post Published",
                    "Your post was published: " + preview,
                    UUID.fromString(event.getPostId()),
                    "POST"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process POST_CREATED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.group-created:notification.group.created}")
    public void handleGroupCreated(EventEnvelope envelope) {
        log.info("Received GROUP_CREATED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof GroupCreatedEvent event) {
                UUID ownerId = UUID.fromString(event.getOwnerId());
                notificationService.createNotification(
                    ownerId,
                    NotificationType.GROUP_INVITE,
                    "Group Created",
                    "Your group \"" + event.getName() + "\" has been created successfully",
                    UUID.fromString(event.getGroupId()),
                    "GROUP"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process GROUP_CREATED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.mentorship-scheduled:notification.mentorship.scheduled}")
    public void handleMentorshipScheduled(EventEnvelope envelope) {
        log.info("Received MENTORSHIP_SCHEDULED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof MentorshipScheduledEvent event) {
                UUID mentorId = UUID.fromString(event.getMentorId());
                UUID menteeId = UUID.fromString(event.getMenteeId());
                UUID mentorshipId = UUID.fromString(event.getMentorshipId());
                String topic = event.getTopic() != null ? event.getTopic() : "General";

                notificationService.createNotification(
                    mentorId,
                    NotificationType.MENTORSHIP_REQUEST,
                    "Mentorship Scheduled",
                    "You have a mentorship session scheduled on topic: " + topic,
                    mentorshipId,
                    "MENTORSHIP"
                );

                notificationService.createNotification(
                    menteeId,
                    NotificationType.MENTORSHIP_REQUEST,
                    "Mentorship Scheduled",
                    "Your mentorship session on \"" + topic + "\" has been scheduled",
                    mentorshipId,
                    "MENTORSHIP"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process MENTORSHIP_SCHEDULED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.badge-unlocked:notification.badge.unlocked}")
    public void handleBadgeUnlocked(EventEnvelope envelope) {
        log.info("Received BADGE_UNLOCKED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof BadgeUnlockedEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                String badgeName = event.getBadgeName();
                notificationService.createNotification(
                    userId,
                    NotificationType.BADGE_UNLOCKED,
                    "Badge Unlocked",
                    "Congratulations! You earned the \"" + badgeName + "\" badge!",
                    UUID.fromString(event.getBadgeId()),
                    "BADGE"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process BADGE_UNLOCKED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.user-registered:notification.user.registered}")
    public void handleUserRegistered(EventEnvelope envelope) {
        log.info("Received USER_REGISTERED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof UserRegisteredEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                String fullName = event.getFullName() != null ? event.getFullName() : event.getUsername();
                notificationService.createNotification(
                    userId,
                    NotificationType.SYSTEM,
                    "Welcome to Pitaya!",
                    "Welcome " + fullName + "! We're excited to have you on board.",
                    null,
                    "SYSTEM"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process USER_REGISTERED event: {}", e.getMessage(), e);
        }
    }

    @RabbitListener(queues = "${notification-service.rabbitmq.queue.profile-updated:notification.profile.updated}")
    public void handleProfileUpdated(EventEnvelope envelope) {
        log.info("Received PROFILE_UPDATED event: {}", envelope.getEventId());
        try {
            if (envelope.getPayload() instanceof ProfileUpdatedEvent event) {
                UUID userId = UUID.fromString(event.getUserId());
                notificationService.createNotification(
                    userId,
                    NotificationType.SYSTEM,
                    "Profile Updated",
                    "Your profile has been updated successfully.",
                    null,
                    "SYSTEM"
                );
            } else {
                log.warn("Unexpected payload type: {}", envelope.getPayload().getClass().getName());
            }
        } catch (Exception e) {
            log.error("Failed to process PROFILE_UPDATED event: {}", e.getMessage(), e);
        }
    }
}
