package com.pitaya.gamification.service;

import com.pitaya.gamification.client.UserServiceClient;
import com.pitaya.gamification.client.dto.UserProfileResponse;
import com.pitaya.gamification.dto.response.BadgeResponse;
import com.pitaya.gamification.dto.response.GamificationResponse;
import com.pitaya.gamification.dto.response.LeaderboardEntryResponse;
import com.pitaya.gamification.dto.response.XpTransactionResponse;
import com.pitaya.gamification.entity.Badge;
import com.pitaya.gamification.entity.UserBadge;
import com.pitaya.gamification.entity.UserGamification;
import com.pitaya.gamification.entity.XpTransaction;
import com.pitaya.gamification.event.producer.GamificationEventProducer;
import com.pitaya.gamification.mapper.BadgeMapper;
import com.pitaya.gamification.mapper.GamificationMapper;
import com.pitaya.gamification.repository.BadgeRepository;
import com.pitaya.gamification.repository.UserBadgeRepository;
import com.pitaya.gamification.repository.UserGamificationRepository;
import com.pitaya.gamification.repository.XpTransactionRepository;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional
public class GamificationServiceImpl implements GamificationService {

    private static final Logger log = LoggerFactory.getLogger(GamificationServiceImpl.class);

    private static final int XP_BASE = 100;

    private final UserGamificationRepository userGamificationRepository;
    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final XpTransactionRepository xpTransactionRepository;
    private final BadgeMapper badgeMapper;
    private final GamificationMapper gamificationMapper;
    private final GamificationEventProducer eventProducer;
    private final UserServiceClient userServiceClient;

    public GamificationServiceImpl(UserGamificationRepository userGamificationRepository,
                                    BadgeRepository badgeRepository,
                                    UserBadgeRepository userBadgeRepository,
                                    XpTransactionRepository xpTransactionRepository,
                                    BadgeMapper badgeMapper,
                                    GamificationMapper gamificationMapper,
                                    GamificationEventProducer eventProducer,
                                    UserServiceClient userServiceClient) {
        this.userGamificationRepository = userGamificationRepository;
        this.badgeRepository = badgeRepository;
        this.userBadgeRepository = userBadgeRepository;
        this.xpTransactionRepository = xpTransactionRepository;
        this.badgeMapper = badgeMapper;
        this.gamificationMapper = gamificationMapper;
        this.eventProducer = eventProducer;
        this.userServiceClient = userServiceClient;
    }

    @Override
    @Transactional(readOnly = true)
    public GamificationResponse getUserGamification(UUID userId) {
        UserGamification gamification = userGamificationRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("UserGamification", "userId", userId));

        List<Badge> allBadges = badgeRepository.findAllByOrderByXpRequired();
        List<UserBadge> userBadges = userBadgeRepository.findByUserId(userId);
        Map<UUID, UserBadge> userBadgeMap = userBadges.stream()
            .collect(Collectors.toMap(UserBadge::getBadgeId, Function.identity()));

        List<BadgeResponse> badgeResponses = allBadges.stream()
            .map(badge -> {
                BadgeResponse response = badgeMapper.toResponse(badge);
                UserBadge ub = userBadgeMap.get(badge.getId());
                if (ub != null) {
                    response.setUnlocked(true);
                    response.setUnlockedAt(ub.getUnlockedAt());
                } else {
                    response.setUnlocked(false);
                    response.setUnlockedAt(null);
                }
                return response;
            })
            .collect(Collectors.toList());

        int xpToNextLevel = getXpToNextLevel(gamification.getLevel(), gamification.getXpPoints());

        return GamificationResponse.builder()
            .userId(gamification.getUserId())
            .xpPoints(gamification.getXpPoints())
            .level(gamification.getLevel())
            .xpToNextLevel(xpToNextLevel)
            .badges(badgeResponses)
            .build();
    }

    @Override
    public GamificationResponse awardXp(UUID userId, int amount, String reason,
                                         String referenceId, String referenceType) {
        UserGamification gamification = userGamificationRepository.findByUserId(userId)
            .orElseGet(() -> {
                UserGamification newGam = UserGamification.builder()
                    .userId(userId)
                    .xpPoints(0)
                    .level(1)
                    .build();
                return userGamificationRepository.save(newGam);
            });

        gamification.setXpPoints(gamification.getXpPoints() + amount);
        int newLevel = getLevel(gamification.getXpPoints());
        gamification.setLevel(newLevel);
        gamification = userGamificationRepository.save(gamification);

        XpTransaction transaction = XpTransaction.builder()
            .userId(userId)
            .amount(amount)
            .reason(reason)
            .referenceId(referenceId)
            .referenceType(referenceType)
            .build();
        xpTransactionRepository.save(transaction);

        log.info("Awarded {} XP to user {} for reason '{}': total XP={}, level={}",
            amount, userId, reason, gamification.getXpPoints(), newLevel);

        checkBadges(userId);

        return getUserGamification(userId);
    }

    @Override
    public int getLevel(int xpPoints) {
        return (int) (Math.sqrt((double) xpPoints / XP_BASE) + 1);
    }

    @Override
    public List<BadgeResponse> checkBadges(UUID userId) {
        UserGamification gamification = userGamificationRepository.findByUserId(userId)
            .orElse(null);
        if (gamification == null) {
            return List.of();
        }

        List<Badge> allBadges = badgeRepository.findAllByOrderByXpRequired();
        List<UserBadge> existingUserBadges = userBadgeRepository.findByUserId(userId);
        Map<UUID, UserBadge> existingBadgeMap = existingUserBadges.stream()
            .collect(Collectors.toMap(UserBadge::getBadgeId, Function.identity()));

        List<BadgeResponse> newlyUnlocked = new ArrayList<>();

        for (Badge badge : allBadges) {
            if (existingBadgeMap.containsKey(badge.getId())) {
                continue;
            }

            boolean shouldUnlock = false;

            if ("Scholar".equals(badge.getName()) && gamification.getLevel() >= 10) {
                shouldUnlock = true;
            } else if ("Contributor".equals(badge.getName()) && gamification.getLevel() >= 25) {
                shouldUnlock = true;
            } else if (badge.getXpRequired() > 0 && gamification.getXpPoints() >= badge.getXpRequired()) {
                shouldUnlock = true;
            }

            if (shouldUnlock) {
                UserBadge userBadge = UserBadge.builder()
                    .userId(userId)
                    .badgeId(badge.getId())
                    .build();
                userBadgeRepository.save(userBadge);

                BadgeResponse response = badgeMapper.toResponse(badge);
                response.setUnlocked(true);
                response.setUnlockedAt(userBadge.getUnlockedAt());
                newlyUnlocked.add(response);

                eventProducer.publishBadgeUnlocked(userId, badge);
                log.info("Badge '{}' unlocked for user {}", badge.getName(), userId);
            }
        }

        return newlyUnlocked;
    }

    @Override
    @Transactional(readOnly = true)
    public List<LeaderboardEntryResponse> getLeaderboard(int limit) {
        List<UserGamification> topUsers = userGamificationRepository.findAllByOrderByXpPointsDesc()
            .stream()
            .limit(limit)
            .collect(Collectors.toList());

        List<LeaderboardEntryResponse> entries = new ArrayList<>();
        int rank = 1;

        for (UserGamification ug : topUsers) {
            LeaderboardEntryResponse entry = LeaderboardEntryResponse.builder()
                .userId(ug.getUserId())
                .xpPoints(ug.getXpPoints())
                .level(ug.getLevel())
                .rank(rank++)
                .build();

            enrichWithUserInfo(entry);
            entries.add(entry);
        }

        return entries;
    }

    @Override
    @Transactional(readOnly = true)
    public int getRank(UUID userId) {
        UserGamification current = userGamificationRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("UserGamification", "userId", userId));

        List<UserGamification> allUsers = userGamificationRepository.findAllByOrderByXpPointsDesc();
        int rank = 1;
        for (UserGamification ug : allUsers) {
            if (ug.getUserId().equals(userId)) {
                return rank;
            }
            rank++;
        }
        return rank;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<XpTransactionResponse> getXpHistory(UUID userId, Pageable pageable) {
        Page<XpTransaction> transactions = xpTransactionRepository
            .findByUserIdOrderByCreatedAtDesc(userId, pageable);
        return transactions.map(gamificationMapper::toXpTransactionResponse);
    }

    private int getXpToNextLevel(int currentLevel, int currentXp) {
        int xpForNextLevel = XP_BASE * (currentLevel * currentLevel);
        return xpForNextLevel - currentXp;
    }

    private void enrichWithUserInfo(LeaderboardEntryResponse entry) {
        try {
            var response = userServiceClient.getUserProfile(entry.getUserId());
            if (response != null && response.getData() != null) {
                UserProfileResponse user = response.getData();
                entry.setAvatar(user.getAvatar());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch user info for leaderboard entry: {}", entry.getUserId(), e);
        }
    }
}
