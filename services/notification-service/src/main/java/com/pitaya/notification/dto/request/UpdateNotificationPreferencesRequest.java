package com.pitaya.notification.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateNotificationPreferencesRequest {

    private boolean emailLikes;
    private boolean emailComments;
    private boolean emailFollows;
    private boolean emailMentorship;
    private boolean emailGroups;
    private boolean emailBadges;
    private boolean pushEnabled;
    private boolean inAppEnabled;
}
