package com.pitaya.group.config;

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

    public static final String GROUP_EXCHANGE = "pitaya.group";

    public static final String GROUP_CREATED_ROUTING_KEY = "group.created";

    @Value("${group-service.rabbitmq.queue.group-created:group.created}")
    private String groupCreatedQueue;

    @Bean
    public TopicExchange groupExchange() {
        return new TopicExchange(GROUP_EXCHANGE, true, false);
    }

    @Bean
    public Queue groupCreatedQueue() {
        return new Queue(groupCreatedQueue, true);
    }

    @Bean
    public Binding groupCreatedBinding(Queue groupCreatedQueue, TopicExchange groupExchange) {
        return BindingBuilder
            .bind(groupCreatedQueue)
            .to(groupExchange)
            .with(GROUP_CREATED_ROUTING_KEY);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
