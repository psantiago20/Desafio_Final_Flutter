package com.pitaya.post.event.producer;

import com.pitaya.post.config.RabbitMqConfig;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.CommentAddedEvent;
import com.pitaya.shared.event.events.PostCreatedEvent;
import com.pitaya.shared.event.events.PostLikedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class PostEventProducer {

    private static final Logger log = LoggerFactory.getLogger(PostEventProducer.class);
    private static final String SOURCE = "post-service";

    private final RabbitTemplate rabbitTemplate;

    public PostEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishPostCreatedEvent(UUID postId, UUID userId, String content,
                                         List<String> mediaUrls, List<String> tags,
                                         String visibility) {
        PostCreatedEvent payload = PostCreatedEvent.builder()
            .postId(postId.toString())
            .userId(userId.toString())
            .content(content)
            .mediaUrls(mediaUrls)
            .tags(tags)
            .visibility(visibility)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "POST_CREATED", SOURCE, userId.toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.POST_EXCHANGE,
            RabbitMqConfig.POST_CREATED_ROUTING_KEY,
            envelope);

        log.info("Published POST_CREATED event for post: {}", postId);
    }

    public void publishCommentAddedEvent(UUID commentId, UUID postId, UUID userId,
                                          String content, UUID parentCommentId) {
        CommentAddedEvent payload = CommentAddedEvent.builder()
            .commentId(commentId.toString())
            .postId(postId.toString())
            .userId(userId.toString())
            .content(content)
            .parentCommentId(parentCommentId != null ? parentCommentId.toString() : null)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "COMMENT_ADDED", SOURCE, userId.toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.POST_EXCHANGE,
            RabbitMqConfig.COMMENT_ADDED_ROUTING_KEY,
            envelope);

        log.info("Published COMMENT_ADDED event for comment: {} on post: {}", commentId, postId);
    }

    public void publishPostLikedEvent(UUID postId, UUID userId, UUID postAuthorId, boolean liked) {
        PostLikedEvent payload = PostLikedEvent.builder()
            .postId(postId.toString())
            .userId(userId.toString())
            .postAuthorId(postAuthorId.toString())
            .liked(liked)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "POST_LIKED", SOURCE, userId.toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.POST_EXCHANGE,
            RabbitMqConfig.POST_LIKED_ROUTING_KEY,
            envelope);

        log.info("Published POST_LIKED event for post: {} (liked: {})", postId, liked);
    }
}
