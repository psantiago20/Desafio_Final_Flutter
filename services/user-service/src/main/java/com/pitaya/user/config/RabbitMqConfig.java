package com.pitaya.user.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.rabbit.annotation.EnableRabbit;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableRabbit
public class RabbitMqConfig {

    public static final String USER_EXCHANGE = "pitaya.user";
    public static final String USER_REGISTERED_QUEUE = "user.registered";
    public static final String USER_REGISTERED_ROUTING_KEY = "user.registered";
    public static final String USER_PROFILE_UPDATED_QUEUE = "user.profile.updated";
    public static final String USER_PROFILE_UPDATED_ROUTING_KEY = "user.profile.updated";

    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange(USER_EXCHANGE, true, false);
    }

    @Bean
    public Queue userRegisteredQueue() {
        return new Queue(USER_REGISTERED_QUEUE, true);
    }

    @Bean
    public Queue userProfileUpdatedQueue() {
        return new Queue(USER_PROFILE_UPDATED_QUEUE, true);
    }

    @Bean
    public Binding userRegisteredBinding(Queue userRegisteredQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(userRegisteredQueue)
            .to(userExchange)
            .with(USER_REGISTERED_ROUTING_KEY);
    }

    @Bean
    public Binding userProfileUpdatedBinding(Queue userProfileUpdatedQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(userProfileUpdatedQueue)
            .to(userExchange)
            .with(USER_PROFILE_UPDATED_ROUTING_KEY);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
