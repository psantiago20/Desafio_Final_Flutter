package com.pitaya.notification.config;

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

    public static final String NOTIFICATION_EXCHANGE = "pitaya.notification";
    public static final String USER_EXCHANGE = "pitaya.user";
    public static final String POST_EXCHANGE = "pitaya.post";
    public static final String GROUP_EXCHANGE = "pitaya.group";
    public static final String MENTORSHIP_EXCHANGE = "pitaya.mentorship";
    public static final String GAMIFICATION_EXCHANGE = "pitaya.gamification";

    public static final String NOTIFICATION_SENT_ROUTING_KEY = "notification.sent";

    @Value("${notification-service.rabbitmq.queue.post-liked:notification.post.liked}")
    private String postLikedQueue;

    @Value("${notification-service.rabbitmq.queue.comment-added:notification.post.comment.added}")
    private String commentAddedQueue;

    @Value("${notification-service.rabbitmq.queue.post-created:notification.post.created}")
    private String postCreatedQueue;

    @Value("${notification-service.rabbitmq.queue.group-created:notification.group.created}")
    private String groupCreatedQueue;

    @Value("${notification-service.rabbitmq.queue.mentorship-scheduled:notification.mentorship.scheduled}")
    private String mentorshipScheduledQueue;

    @Value("${notification-service.rabbitmq.queue.badge-unlocked:notification.badge.unlocked}")
    private String badgeUnlockedQueue;

    @Value("${notification-service.rabbitmq.queue.user-registered:notification.user.registered}")
    private String userRegisteredQueue;

    @Value("${notification-service.rabbitmq.queue.profile-updated:notification.profile.updated}")
    private String profileUpdatedQueue;

    @Bean
    public TopicExchange notificationExchange() {
        return new TopicExchange(NOTIFICATION_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange userExchange() {
        return new TopicExchange(USER_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange postExchange() {
        return new TopicExchange(POST_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange groupExchange() {
        return new TopicExchange(GROUP_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange mentorshipExchange() {
        return new TopicExchange(MENTORSHIP_EXCHANGE, true, false);
    }

    @Bean
    public TopicExchange gamificationExchange() {
        return new TopicExchange(GAMIFICATION_EXCHANGE, true, false);
    }

    @Bean
    public Queue postLikedQueue() {
        return new Queue(postLikedQueue, true);
    }

    @Bean
    public Queue commentAddedQueue() {
        return new Queue(commentAddedQueue, true);
    }

    @Bean
    public Queue postCreatedQueue() {
        return new Queue(postCreatedQueue, true);
    }

    @Bean
    public Queue groupCreatedQueue() {
        return new Queue(groupCreatedQueue, true);
    }

    @Bean
    public Queue mentorshipScheduledQueue() {
        return new Queue(mentorshipScheduledQueue, true);
    }

    @Bean
    public Queue badgeUnlockedQueue() {
        return new Queue(badgeUnlockedQueue, true);
    }

    @Bean
    public Queue userRegisteredQueue() {
        return new Queue(userRegisteredQueue, true);
    }

    @Bean
    public Queue profileUpdatedQueue() {
        return new Queue(profileUpdatedQueue, true);
    }

    @Bean
    public Binding postLikedBinding(Queue postLikedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postLikedQueue)
            .to(postExchange)
            .with("post.liked");
    }

    @Bean
    public Binding commentAddedBinding(Queue commentAddedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(commentAddedQueue)
            .to(postExchange)
            .with("post.comment.added");
    }

    @Bean
    public Binding postCreatedBinding(Queue postCreatedQueue, TopicExchange postExchange) {
        return BindingBuilder
            .bind(postCreatedQueue)
            .to(postExchange)
            .with("post.created");
    }

    @Bean
    public Binding groupCreatedBinding(Queue groupCreatedQueue, TopicExchange groupExchange) {
        return BindingBuilder
            .bind(groupCreatedQueue)
            .to(groupExchange)
            .with("group.created");
    }

    @Bean
    public Binding mentorshipScheduledBinding(Queue mentorshipScheduledQueue, TopicExchange mentorshipExchange) {
        return BindingBuilder
            .bind(mentorshipScheduledQueue)
            .to(mentorshipExchange)
            .with("mentorship.scheduled");
    }

    @Bean
    public Binding badgeUnlockedBinding(Queue badgeUnlockedQueue, TopicExchange gamificationExchange) {
        return BindingBuilder
            .bind(badgeUnlockedQueue)
            .to(gamificationExchange)
            .with("badge.unlocked");
    }

    @Bean
    public Binding userRegisteredBinding(Queue userRegisteredQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(userRegisteredQueue)
            .to(userExchange)
            .with("user.registered");
    }

    @Bean
    public Binding profileUpdatedBinding(Queue profileUpdatedQueue, TopicExchange userExchange) {
        return BindingBuilder
            .bind(profileUpdatedQueue)
            .to(userExchange)
            .with("profile.updated");
    }

    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
