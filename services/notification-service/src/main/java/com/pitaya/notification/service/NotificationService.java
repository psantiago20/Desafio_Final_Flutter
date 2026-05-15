package com.pitaya.notification.service;

import com.pitaya.notification.dto.request.UpdateNotificationPreferencesRequest;
import com.pitaya.notification.dto.response.NotificationPreferenceResponse;
import com.pitaya.notification.dto.response.NotificationResponse;
import com.pitaya.notification.entity.NotificationType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface NotificationService {

    Page<NotificationResponse> getNotifications(UUID userId, Pageable pageable);

    int getUnreadCount(UUID userId);

    void markAsRead(UUID userId, List<UUID> notificationIds);

    void markAllAsRead(UUID userId);

    NotificationResponse createNotification(UUID userId, NotificationType type, String title,
                                             String message, UUID referenceId, String referenceType);

    void deleteOldNotifications(int retentionDays);

    NotificationPreferenceResponse getPreferences(UUID userId);

    NotificationPreferenceResponse updatePreferences(UUID userId,
                                                      UpdateNotificationPreferencesRequest request);
}
