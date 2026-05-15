package com.pitaya.group.event.producer;

import com.pitaya.group.config.RabbitMqConfig;
import com.pitaya.group.entity.Group;
import com.pitaya.group.enums.GroupVisibility;
import com.pitaya.shared.event.EventEnvelope;
import com.pitaya.shared.event.events.GroupCreatedEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
public class GroupEventProducer {

    private static final Logger log = LoggerFactory.getLogger(GroupEventProducer.class);
    private static final String SOURCE = "group-service";

    private final RabbitTemplate rabbitTemplate;

    public GroupEventProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishGroupCreatedEvent(Group group) {
        GroupCreatedEvent payload = GroupCreatedEvent.builder()
            .groupId(group.getId().toString())
            .name(group.getName())
            .description(group.getDescription())
            .ownerId(group.getOwnerId().toString())
            .category(group.getCategory())
            .isPrivate(group.getVisibility() != GroupVisibility.PUBLIC)
            .build();

        EventEnvelope envelope = EventEnvelope.from(
            "GROUP_CREATED", SOURCE, group.getOwnerId().toString(), payload);

        rabbitTemplate.convertAndSend(
            RabbitMqConfig.GROUP_EXCHANGE,
            RabbitMqConfig.GROUP_CREATED_ROUTING_KEY,
            envelope);

        log.info("Published GROUP_CREATED event for group: {}", group.getId());
    }
}
