package com.pitaya.library.config;

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

    public static final String LIBRARY_EXCHANGE = "pitaya.library";

    public static final String MATERIAL_CREATED_ROUTING_KEY = "material.created";

    @Value("${library-service.rabbitmq.queue.material-created:material.created}")
    private String materialCreatedQueue;

    @Bean
    public TopicExchange libraryExchange() {
        return new TopicExchange(LIBRARY_EXCHANGE, true, false);
    }

    @Bean
    public Queue materialCreatedQueue() {
        return new Queue(materialCreatedQueue, true);
    }

    @Bean
    public Binding materialCreatedBinding(Queue materialCreatedQueue, TopicExchange libraryExchange) {
        return BindingBuilder
            .bind(materialCreatedQueue)
            .to(libraryExchange)
            .with(MATERIAL_CREATED_ROUTING_KEY);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
