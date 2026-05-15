package com.pitaya.gamification.service;

import com.pitaya.gamification.dto.response.BadgeResponse;
import com.pitaya.gamification.dto.response.GamificationResponse;
import com.pitaya.gamification.dto.response.LeaderboardEntryResponse;
import com.pitaya.gamification.dto.response.XpTransactionResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface GamificationService {

    GamificationResponse getUserGamification(UUID userId);

    GamificationResponse awardXp(UUID userId, int amount, String reason, String referenceId, String referenceType);

    int getLevel(int xpPoints);

    List<BadgeResponse> checkBadges(UUID userId);

    List<LeaderboardEntryResponse> getLeaderboard(int limit);

    int getRank(UUID userId);

    Page<XpTransactionResponse> getXpHistory(UUID userId, Pageable pageable);
}
