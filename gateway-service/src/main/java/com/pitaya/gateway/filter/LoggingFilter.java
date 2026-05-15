package com.pitaya.gateway.filter;

import lombok.extern.slf4j.Slf4j;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Slf4j
@Component
public class LoggingFilter implements GlobalFilter, Ordered {

    private static final String CORRELATION_ID_HEADER = "X-Correlation-Id";
    private static final String START_TIME_ATTR = "startTime";

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();

        String correlationId = request.getHeaders().getFirst(CORRELATION_ID_HEADER);
        if (correlationId == null) {
            correlationId = UUID.randomUUID().toString();
        }

        ServerHttpRequest mutatedRequest = request.mutate()
                .header(CORRELATION_ID_HEADER, correlationId)
                .build();

        ServerWebExchange mutatedExchange = exchange.mutate()
                .request(mutatedRequest)
                .build();

        mutatedExchange.getAttributes().put(START_TIME_ATTR, System.currentTimeMillis());
        mutatedExchange.getAttributes().put(CORRELATION_ID_HEADER, correlationId);

        log.info("[{}] --> {} {} | Headers: {}",
                correlationId,
                mutatedRequest.getMethod(),
                mutatedRequest.getURI().getPath(),
                mutatedRequest.getHeaders().entrySet().stream()
                        .filter(e -> !e.getKey().equalsIgnoreCase("authorization"))
                        .map(e -> e.getKey() + ":" + e.getValue())
                        .toList());

        return chain.filter(mutatedExchange).then(Mono.fromRunnable(() -> {
            ServerHttpResponse response = mutatedExchange.getResponse();
            Long startTime = mutatedExchange.getAttribute(START_TIME_ATTR);
            long duration = startTime != null ? System.currentTimeMillis() - startTime : 0;

            log.info("[{}] <-- {} {} | Status: {} | Duration: {}ms",
                    mutatedExchange.getAttribute(CORRELATION_ID_HEADER),
                    mutatedRequest.getMethod(),
                    mutatedRequest.getURI().getPath(),
                    response.getStatusCode(),
                    duration);
        }));
    }

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE;
    }
}
