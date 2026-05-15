package com.pitaya.group.dto.response;

import com.pitaya.group.enums.InviteStatus;
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
public class InviteResponse {

    private UUID id;
    private UUID groupId;
    private String groupName;
    private UUID invitedBy;
    private String invitedByDisplayName;
    private UUID invitedUser;
    private String invitedUserDisplayName;
    private InviteStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime respondedAt;
}
