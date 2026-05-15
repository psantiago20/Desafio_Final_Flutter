package com.pitaya.mentorship.event.producer;

import com.pitaya.mentorship.config.RabbitMqConfig;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.MentorshipScheduledEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.UUID;

@Component
public class MentorshipEventProducer {

    private static final Logger log = LoggerFactory.getLogger(MentorshipEventProducer.class);
    private static final String SOURCE = "mentorship-service";

    private final RabbitTemplate rabbitTemplate;

    public MentorshipEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishMentorshipScheduledEvent(UUID mentorshipId, UUID mentorId, UUID menteeId,
                                                  LocalDateTime startTime, LocalDateTime endTime,
                                                  String topic, String status) {
        MentorshipScheduledEvent payload = MentorshipScheduledEvent.builder()
            .mentorshipId(mentorshipId.toString())
            .mentorId(mentorId.toString())
            .menteeId(menteeId.toString())
            .startTime(startTime.toInstant(ZoneOffset.UTC).toEpochMilli())
            .endTime(endTime.toInstant(ZoneOffset.UTC).toEpochMilli())
            .topic(topic)
            .status(status)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "MENTORSHIP_SCHEDULED", SOURCE, mentorId.toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.MENTORSHIP_EXCHANGE,
            RabbitMqConfig.MENTORSHIP_SCHEDULED_ROUTING_KEY,
            envelope);

        log.info("Published MENTORSHIP_SCHEDULED event for mentorship: {}", mentorshipId);
    }
}
