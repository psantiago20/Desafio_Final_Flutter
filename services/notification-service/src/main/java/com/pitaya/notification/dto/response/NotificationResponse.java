package com.pitaya.notification.dto.response;

import com.pitaya.notification.entity.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {

    private UUID id;
    private UUID userId;
    private NotificationType type;
    private String title;
    private String message;
    private UUID referenceId;
    private String referenceType;
    private boolean isRead;
    private LocalDateTime createdAt;
}
