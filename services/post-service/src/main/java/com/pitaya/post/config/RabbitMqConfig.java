package com.pitaya.post.config;

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

    public static final String POST_EXCHANGE = "pitaya.post";
    public static final String USER_EXCHANGE = "pitaya.user";

    public static final String POST_CREATED_ROUTING_KEY = "post.created";
    public static final String COMMENT_ADDED_ROUTING_KEY = "post.comment.added";
    public static final String POST_LIKED_ROUTING_KEY = "post.liked";

    @Value("${post-service.rabbitmq.queue.post-created:post.created}")
    private String postCreatedQueue;

    @Value("${post-service.rabbitmq.queue.comment-added:post.comment.added}")
    private String commentAddedQueue;

    @Value("${post-service.rabbitmq.queue.post-liked:post.liked}")
    private String postLikedQueue;

    @Value("${post-service.rabbitmq.queue.profile-updated:user.profile.updated}")
    private String profileUpdatedQueue;

    @Bean
    public TopicExchange postExchange() {
        return new TopicExchange(POST_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange(USER_EXCHANGE, true, false);
    }

    @Bean
    public Queue postCreatedQueue() {
        return new Queue(postCreatedQueue, true);
    }

    @Bean
    public Queue commentAddedQueue() {
        return new Queue(commentAddedQueue, true);
    }

    @Bean
    public Queue postLikedQueue() {
        return new Queue(postLikedQueue, true);
    }

    @Bean
    public Queue profileUpdatedQueue() {
        return new Queue(profileUpdatedQueue, true);
    }

    @Bean
    public Binding postCreatedBinding(Queue postCreatedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postCreatedQueue)
            .to(postExchange)
            .with(POST_CREATED_ROUTING_KEY);
    }

    @Bean
    public Binding commentAddedBinding(Queue commentAddedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(commentAddedQueue)
            .to(postExchange)
            .with(COMMENT_ADDED_ROUTING_KEY);
    }

    @Bean
    public Binding postLikedBinding(Queue postLikedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postLikedQueue)
            .to(postExchange)
            .with(POST_LIKED_ROUTING_KEY);
    }

    @Bean
    public Binding profileUpdatedBinding(Queue profileUpdatedQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(profileUpdatedQueue)
            .to(userExchange)
            .with("user.profile.updated");
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
