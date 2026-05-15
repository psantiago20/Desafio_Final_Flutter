package com.pitaya.gamification.dto.response;

import com.pitaya.gamification.entity.BadgeCategory;
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
public class BadgeResponse {

    private UUID id;
    private String name;
    private String description;
    private String iconUrl;
    private BadgeCategory category;
    private boolean unlocked;
    private LocalDateTime unlockedAt;
}
