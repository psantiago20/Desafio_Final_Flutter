package com.pitaya.group.dto.response;

import com.pitaya.group.enums.GroupVisibility;
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
public class GroupResponse {

    private UUID id;
    private String name;
    private String description;
    private String bannerUrl;
    private String category;
    private GroupVisibility visibility;
    private UUID ownerId;
    private String ownerDisplayName;
    private String ownerUsername;
    private String ownerAvatar;
    private int memberCount;
    private boolean active;
    private boolean isMember;
    private String membershipRole;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
