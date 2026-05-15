package com.pitaya.gamification.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GamificationResponse {

    private UUID userId;
    private int xpPoints;
    private int level;
    private int xpToNextLevel;
    private List<BadgeResponse> badges;
}
