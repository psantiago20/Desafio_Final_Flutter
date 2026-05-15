package com.pitaya.gamification.service;

import com.pitaya.gamification.entity.Badge;
import com.pitaya.gamification.repository.BadgeRepository;
import com.pitaya.gamification.repository.UserBadgeRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class EventHandlerServiceImpl implements EventHandlerService {

    private static final Logger log = LoggerFactory.getLogger(EventHandlerServiceImpl.class);

    private static final String REASON_POST_CREATED = "POST_CREATED";
    private static final String REASON_COMMENT_ADDED = "COMMENT_ADDED";
    private static final String REASON_POST_LIKED = "POST_LIKED";
    private static final String REASON_USER_REGISTERED = "USER_REGISTERED";
    private static final String REASON_MENTORSHIP_SCHEDULED = "MENTORSHIP_SCHEDULED";

    private static final String REF_TYPE_POST = "POST";
    private static final String REF_TYPE_COMMENT = "COMMENT";
    private static final String REF_TYPE_LIKE = "LIKE";
    private static final String REF_TYPE_USER = "USER";
    private static final String REF_TYPE_MENTORSHIP = "MENTORSHIP";

    private static final int XP_POST_CREATED = 10;
    private static final int XP_COMMENT_ADDED = 5;
    private static final int XP_POST_LIKED = 2;
    private static final int XP_USER_REGISTERED = 100;
    private static final int XP_MENTORSHIP_SCHEDULED = 25;

    private final GamificationService gamificationService;
    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;

    public EventHandlerServiceImpl(GamificationService gamificationService,
                                    BadgeRepository badgeRepository,
                                    UserBadgeRepository userBadgeRepository) {
        this.gamificationService = gamificationService;
        this.badgeRepository = badgeRepository;
        this.userBadgeRepository = userBadgeRepository;
    }

    @Override
    public void handlePostCreated(UUID userId, String postId) {
        try {
            gamificationService.awardXp(userId, XP_POST_CREATED, REASON_POST_CREATED, postId, REF_TYPE_POST);
            checkFirstPostBadge(userId);
            log.debug("Awarded {} XP for post creation to user {}", XP_POST_CREATED, userId);
        } catch (Exception e) {
            log.error("Failed to handle POST_CREATED event for user {}: {}", userId, e.getMessage(), e);
        }
    }

    @Override
    public void handleCommentAdded(UUID userId, String commentId, String postId) {
        try {
            gamificationService.awardXp(userId, XP_COMMENT_ADDED, REASON_COMMENT_ADDED, commentId, REF_TYPE_COMMENT);
            checkCommenterBadge(userId);
            log.debug("Awarded {} XP for comment to user {}", XP_COMMENT_ADDED, userId);
        } catch (Exception e) {
            log.error("Failed to handle COMMENT_ADDED event for user {}: {}", userId, e.getMessage(), e);
        }
    }

    @Override
    public void handlePostLiked(UUID userId, String postId, String postAuthorId) {
        try {
            gamificationService.awardXp(userId, XP_POST_LIKED, REASON_POST_LIKED, postId, REF_TYPE_LIKE);
            log.debug("Awarded {} XP for like to user {}", XP_POST_LIKED, userId);
        } catch (Exception e) {
            log.error("Failed to handle POST_LIKED event for user {}: {}", userId, e.getMessage(), e);
        }
    }

    @Override
    public void handleUserRegistered(UUID userId, String email, String username, String fullName) {
        try {
            gamificationService.awardXp(userId, XP_USER_REGISTERED, REASON_USER_REGISTERED,
                userId.toString(), REF_TYPE_USER);
            checkWelcomeBadge(userId);
            log.debug("Awarded {} XP for registration to user {}", XP_USER_REGISTERED, userId);
        } catch (Exception e) {
            log.error("Failed to handle USER_REGISTERED event for user {}: {}", userId, e.getMessage(), e);
        }
    }

    @Override
    public void handleMentorshipScheduled(UUID mentorId, UUID menteeId, String mentorshipId) {
        try {
            gamificationService.awardXp(mentorId, XP_MENTORSHIP_SCHEDULED, REASON_MENTORSHIP_SCHEDULED,
                mentorshipId, REF_TYPE_MENTORSHIP);
            checkMentorBadge(mentorId);
            log.debug("Awarded {} XP for mentorship to user {}", XP_MENTORSHIP_SCHEDULED, mentorId);
        } catch (Exception e) {
            log.error("Failed to handle MENTORSHIP_SCHEDULED event for mentor {}: {}", mentorId, e.getMessage(), e);
        }
    }

    private void checkFirstPostBadge(UUID userId) {
        Badge badge = badgeRepository.findByName("First Post").orElse(null);
        if (badge != null && !userBadgeRepository.existsByUserIdAndBadgeId(userId, badge.getId())) {
            gamificationService.checkBadges(userId);
        }
    }

    private void checkCommenterBadge(UUID userId) {
        Badge badge = badgeRepository.findByName("Commenter").orElse(null);
        if (badge != null && !userBadgeRepository.existsByUserIdAndBadgeId(userId, badge.getId())) {
            gamificationService.checkBadges(userId);
        }
    }

    private void checkWelcomeBadge(UUID userId) {
        Badge badge = badgeRepository.findByName("Welcome").orElse(null);
        if (badge != null && !userBadgeRepository.existsByUserIdAndBadgeId(userId, badge.getId())) {
            gamificationService.checkBadges(userId);
        }
    }

    private void checkMentorBadge(UUID userId) {
        Badge badge = badgeRepository.findByName("Mentor").orElse(null);
        if (badge != null && !userBadgeRepository.existsByUserIdAndBadgeId(userId, badge.getId())) {
            gamificationService.checkBadges(userId);
        }
    }
}
