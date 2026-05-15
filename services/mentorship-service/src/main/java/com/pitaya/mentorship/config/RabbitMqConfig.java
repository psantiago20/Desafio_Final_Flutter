package com.pitaya.mentorship.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableRabbit
public class RabbitMqConfig {

    public static final String MENTORSHIP_EXCHANGE = "pitaya.mentorship";

    public static final String MENTORSHIP_SCHEDULED_ROUTING_KEY = "mentorship.scheduled";

    @Value("${mentorship-service.rabbitmq.queue.mentorship-scheduled:mentorship.scheduled}")
    private String mentorshipScheduledQueue;

    @Bean
    public TopicExchange mentorshipExchange() {
        return new TopicExchange(MENTORSHIP_EXCHANGE, true, false);
    }

    @Bean
    public Queue mentorshipScheduledQueue() {
        return new Queue(mentorshipScheduledQueue, true);
    }

    @Bean
    public Binding mentorshipScheduledBinding(Queue mentorshipScheduledQueue, TopicExchange mentorshipExchange) {
        return BindingBuilder
            .bind(mentorshipScheduledQueue)
            .to(mentorshipExchange)
            .with(MENTORSHIP_SCHEDULED_ROUTING_KEY);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
