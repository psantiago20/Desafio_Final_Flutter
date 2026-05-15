package com.pitaya.gamification.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LeaderboardEntryResponse {

    private UUID userId;
    private String fullName;
    private String username;
    private String avatar;
    private int xpPoints;
    private int level;
    private int rank;
}
