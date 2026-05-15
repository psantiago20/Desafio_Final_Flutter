package com.pitaya.notification.service;

import com.pitaya.notification.dto.request.UpdateNotificationPreferencesRequest;
import com.pitaya.notification.dto.response.NotificationPreferenceResponse;
import com.pitaya.notification.dto.response.NotificationResponse;
import com.pitaya.notification.entity.Notification;
import com.pitaya.notification.entity.NotificationPreference;
import com.pitaya.notification.entity.NotificationType;
import com.pitaya.notification.mapper.NotificationMapper;
import com.pitaya.notification.mapper.NotificationPreferenceMapper;
import com.pitaya.notification.repository.NotificationPreferenceRepository;
import com.pitaya.notification.repository.NotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
public class NotificationServiceImpl implements NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationServiceImpl.class);

    private final NotificationRepository notificationRepository;
    private final NotificationPreferenceRepository preferenceRepository;
    private final NotificationMapper notificationMapper;
    private final NotificationPreferenceMapper preferenceMapper;

    public NotificationServiceImpl(NotificationRepository notificationRepository,
                                    NotificationPreferenceRepository preferenceRepository,
                                    NotificationMapper notificationMapper,
                                    NotificationPreferenceMapper preferenceMapper) {
        this.notificationRepository = notificationRepository;
        this.preferenceRepository = preferenceRepository;
        this.notificationMapper = notificationMapper;
        this.preferenceMapper = preferenceMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<NotificationResponse> getNotifications(UUID userId, Pageable pageable) {
        return notificationRepository
            .findByUserIdOrderByCreatedAtDesc(userId, pageable)
            .map(notificationMapper::toResponse);
    }

    @Override
    @Transactional(readOnly = true)
    @Cacheable(value = "unreadCount", key = "#userId")
    public int getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Override
    @CacheEvict(value = "unreadCount", key = "#userId")
    public void markAsRead(UUID userId, List<UUID> notificationIds) {
        int updated = notificationRepository.markAsRead(userId, notificationIds);
        log.info("Marked {} notifications as read for user {}", updated, userId);
    }

    @Override
    @CacheEvict(value = "unreadCount", key = "#userId")
    public void markAllAsRead(UUID userId) {
        int updated = notificationRepository.markAllAsRead(userId);
        log.info("Marked all {} notifications as read for user {}", updated, userId);
    }

    @Override
    public NotificationResponse createNotification(UUID userId, NotificationType type, String title,
                                                     String message, UUID referenceId, String referenceType) {
        Notification notification = Notification.builder()
            .userId(userId)
            .type(type)
            .title(title)
            .message(message)
            .referenceId(referenceId)
            .referenceType(referenceType)
            .isRead(false)
            .build();

        notification = notificationRepository.save(notification);
        log.info("Created {} notification for user {}: {}", type, userId, title);
        return notificationMapper.toResponse(notification);
    }

    @Override
    @Scheduled(cron = "${notification-service.cleanup.cron:0 0 3 * * ?}")
    public void deleteOldNotifications(int retentionDays) {
        try {
            String prop = System.getProperty("notification-service.cleanup.retention-days");
            if (prop != null) {
                retentionDays = Integer.parseInt(prop);
            }
        } catch (Exception e) {
            // use default
        }
        LocalDateTime cutoff = LocalDateTime.now().minusDays(retentionDays);
        notificationRepository.deleteByCreatedAtBefore(cutoff);
        log.info("Deleted notifications older than {} days", retentionDays);
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationPreferenceResponse getPreferences(UUID userId) {
        NotificationPreference preference = preferenceRepository.findByUserId(userId)
            .orElseGet(() -> createDefaultPreferences(userId));
        return preferenceMapper.toResponse(preference);
    }

    @Override
    public NotificationPreferenceResponse updatePreferences(UUID userId,
                                                             UpdateNotificationPreferencesRequest request) {
        NotificationPreference preference = preferenceRepository.findByUserId(userId)
            .orElseGet(() -> createDefaultPreferences(userId));

        preference.setEmailLikes(request.isEmailLikes());
        preference.setEmailComments(request.isEmailComments());
        preference.setEmailFollows(request.isEmailFollows());
        preference.setEmailMentorship(request.isEmailMentorship());
        preference.setEmailGroups(request.isEmailGroups());
        preference.setEmailBadges(request.isEmailBadges());
        preference.setPushEnabled(request.isPushEnabled());
        preference.setInAppEnabled(request.isInAppEnabled());

        preference = preferenceRepository.save(preference);
        log.info("Updated notification preferences for user {}", userId);
        return preferenceMapper.toResponse(preference);
    }

    private NotificationPreference createDefaultPreferences(UUID userId) {
        NotificationPreference preference = NotificationPreference.builder()
            .userId(userId)
            .emailLikes(true)
            .emailComments(true)
            .emailFollows(true)
            .emailMentorship(true)
            .emailGroups(true)
            .emailBadges(true)
            .pushEnabled(true)
            .inAppEnabled(true)
            .build();
        return preferenceRepository.save(preference);
    }
}
