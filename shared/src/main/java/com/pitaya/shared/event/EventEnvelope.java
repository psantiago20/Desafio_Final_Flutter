package com.pitaya.shared.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventEnvelope implements Serializable {

    private static final long serialVersionUID = 1L;

    private String eventId;
    private String eventType;
    private String source;
    private long timestamp;
    private int version;
    private String correlationId;
    private String userId;
    private Object payload;

    public static EventEnvelope from(String eventType, String source, String userId, Object payload) {
        return EventEnvelope.builder()
                .eventId(UUID.randomUUID().toString())
                .eventType(eventType)
                .source(source)
                .timestamp(Instant.now().toEpochMilli())
                .version(1)
                .correlationId(UUID.randomUUID().toString())
                .userId(userId)
                .payload(payload)
                .build();
    }
}
