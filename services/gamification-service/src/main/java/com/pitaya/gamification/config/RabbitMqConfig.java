package com.pitaya.gamification.config;

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

    public static final String GAMIFICATION_EXCHANGE = "pitaya.gamification";
    public static final String POST_EXCHANGE = "pitaya.post";
    public static final String USER_EXCHANGE = "pitaya.user";
    public static final String MENTORSHIP_EXCHANGE = "pitaya.mentorship";

    public static final String BADGE_UNLOCKED_ROUTING_KEY = "badge.unlocked";

    @Value("${gamification-service.rabbitmq.queue.badge-unlocked:badge.unlocked}")
    private String badgeUnlockedQueue;

    @Value("${gamification-service.rabbitmq.queue.post-created:gamification.post.created}")
    private String postCreatedQueue;

    @Value("${gamification-service.rabbitmq.queue.comment-added:gamification.post.comment.added}")
    private String commentAddedQueue;

    @Value("${gamification-service.rabbitmq.queue.post-liked:gamification.post.liked}")
    private String postLikedQueue;

    @Value("${gamification-service.rabbitmq.queue.user-registered:gamification.user.registered}")
    private String userRegisteredQueue;

    @Value("${gamification-service.rabbitmq.queue.mentorship-scheduled:gamification.mentorship.scheduled}")
    private String mentorshipScheduledQueue;

    @Bean
    public TopicExchange gamificationExchange() {
        return new TopicExchange(GAMIFICATION_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange postExchange() {
        return new TopicExchange(POST_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange(USER_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange mentorshipExchange() {
        return new TopicExchange(MENTORSHIP_EXCHANGE, true, false);
    }

    @Bean
    public Queue badgeUnlockedQueue() {
        return new Queue(badgeUnlockedQueue, true);
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
    public Queue userRegisteredQueue() {
        return new Queue(userRegisteredQueue, true);
    }

    @Bean
    public Queue mentorshipScheduledQueue() {
        return new Queue(mentorshipScheduledQueue, true);
    }

    @Bean
    public Binding badgeUnlockedBinding(Queue badgeUnlockedQueue, TopicExchange gamificationExchange) {
        return BindingBuilder
            .bind(badgeUnlockedQueue)
            .to(gamificationExchange)
            .with(BADGE_UNLOCKED_ROUTING_KEY);
    }

    @Bean
    public Binding postCreatedBinding(Queue postCreatedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postCreatedQueue)
            .to(postExchange)
            .with("post.created");
    }

    @Bean
    public Binding commentAddedBinding(Queue commentAddedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(commentAddedQueue)
            .to(postExchange)
            .with("post.comment.added");
    }

    @Bean
    public Binding postLikedBinding(Queue postLikedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postLikedQueue)
            .to(postExchange)
            .with("post.liked");
    }

    @Bean
    public Binding userRegisteredBinding(Queue userRegisteredQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(userRegisteredQueue)
            .to(userExchange)
            .with("user.registered");
    }

    @Bean
    public Binding mentorshipScheduledBinding(Queue mentorshipScheduledQueue, TopicExchange mentorshipExchange) {
        return BindingBuilder
            .bind(mentorshipScheduledQueue)
            .to(mentorshipExchange)
            .with("mentorship.scheduled");
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
