package com.pitaya.notification.dto.response;

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
public class NotificationPreferenceResponse {

    private UUID id;
    private UUID userId;
    private boolean emailLikes;
    private boolean emailComments;
    private boolean emailFollows;
    private boolean emailMentorship;
    private boolean emailGroups;
    private boolean emailBadges;
    private boolean pushEnabled;
    private boolean inAppEnabled;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
