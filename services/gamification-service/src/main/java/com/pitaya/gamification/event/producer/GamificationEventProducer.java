package com.pitaya.gamification.event.producer;

import com.pitaya.gamification.config.RabbitMqConfig;
import com.pitaya.gamification.entity.Badge;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.BadgeUnlockedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class GamificationEventProducer {

    private static final Logger log = LoggerFactory.getLogger(GamificationEventProducer.class);
    private static final String SOURCE = "gamification-service";

    private final RabbitTemplate rabbitTemplate;

    public GamificationEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishBadgeUnlocked(UUID userId, Badge badge) {
        BadgeUnlockedEvent payload = BadgeUnlockedEvent.builder()
            .badgeId(badge.getId().toString())
            .userId(userId.toString())
            .badgeName(badge.getName())
            .badgeDescription(badge.getDescription())
            .badgeIconUrl(badge.getIconUrl())
            .category(badge.getCategory().name())
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "BADGE_UNLOCKED", SOURCE, userId.toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.GAMIFICATION_EXCHANGE,
            RabbitMqConfig.BADGE_UNLOCKED_ROUTING_KEY,
            envelope);

        log.info("Published BADGE_UNLOCKED event for badge: {} to user: {}", badge.getName(), userId);
    }
}
