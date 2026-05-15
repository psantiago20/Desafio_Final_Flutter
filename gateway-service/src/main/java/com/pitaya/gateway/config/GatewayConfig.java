package com.pitaya.gateway.config;

import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.cloud.circuitbreaker.resilience4j.ReactiveResilience4JCircuitBreakerFactory;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.cloud.gateway.filter.factory.SpringCloudCircuitBreakerFilterFactory;
import org.springframework.cloud.gateway.filter.factory.RequestRateLimiterGatewayFilterFactory;
import org.springframework.cloud.gateway.filter.factory.RetryGatewayFilterFactory;
import org.springframework.cloud.gateway.filter.ratelimit.RateLimiter;
import reactor.core.publisher.Mono;

import java.time.Duration;

@Configuration
public class GatewayConfig {

    private static final int DEFAULT_RETRIES = 3;

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("auth-service", r -> r
                        .path("/api/v1/auth/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("authCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/auth"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://auth-service"))
                .route("user-service", r -> r
                        .path("/api/v1/users/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("userCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/user"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://user-service"))
                .route("post-service", r -> r
                        .path("/api/v1/posts/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("postCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/post"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://post-service"))
                .route("group-service", r -> r
                        .path("/api/v1/groups/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("groupCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/group"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://group-service"))
                .route("library-service", r -> r
                        .path("/api/v1/library/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("libraryCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/library"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://library-service"))
                .route("mentorship-service", r -> r
                        .path("/api/v1/mentorships/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("mentorshipCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/mentorship"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://mentorship-service"))
                .route("gamification-service", r -> r
                        .path("/api/v1/gamification/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("gamificationCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/gamification"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://gamification-service"))
                .route("notification-service", r -> r
                        .path("/api/v1/notifications/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("notificationCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/notification"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://notification-service"))
                .route("message-service", r -> r
                        .path("/api/v1/messages/**")
                        .filters(f -> f
                                .circuitBreaker(cb -> cb
                                        .setName("messageCircuitBreaker")
                                        .setFallbackUri("forward:/fallback/message"))
                                .retry(config -> config
                                        .setRetries(DEFAULT_RETRIES)
                                        .setStatuses(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE))
                                .requestRateLimiter(config -> config
                                        .setRateLimiter(redisRateLimiter())
                                        .setKeyResolver(userKeyResolver()))
                                .stripPrefix(1))
                        .uri("lb://message-service"))
                .build();
    }

    @Bean
    public RedisRateLimiter redisRateLimiter() {
        return new RedisRateLimiter(10, 20, 1);
    }

    @Bean
    public KeyResolver userKeyResolver() {
        return exchange -> {
            String userId = exchange.getRequest().getHeaders().getFirst("X-User-Id");
            if (userId == null) {
                return Mono.just(exchange.getRequest().getRemoteAddress().getAddress().getHostAddress());
            }
            return Mono.just(userId);
        };
    }
}
