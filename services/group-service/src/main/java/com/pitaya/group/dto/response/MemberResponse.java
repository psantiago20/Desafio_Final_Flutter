package com.pitaya.group.dto.response;

import com.pitaya.group.enums.MemberRole;
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
public class MemberResponse {

    private UUID id;
    private UUID userId;
    private String displayName;
    private String username;
    private String avatar;
    private MemberRole role;
    private LocalDateTime joinedAt;
}
