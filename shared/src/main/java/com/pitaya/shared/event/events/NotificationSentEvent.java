package com.pitaya.shared.event.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationSentEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String notificationId;
    private String userId;
    private String type;
    private String title;
    private String body;
    private Map<String, Object> metadata;
}
