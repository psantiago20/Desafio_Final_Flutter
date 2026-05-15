package com.pitaya.notification.controller;

import com.pitaya.notification.dto.request.MarkReadRequest;
import com.pitaya.notification.dto.request.UpdateNotificationPreferencesRequest;
import com.pitaya.notification.dto.response.NotificationPreferenceResponse;
import com.pitaya.notification.dto.response.NotificationResponse;
import com.pitaya.notification.service.NotificationService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<NotificationResponse>>> getNotifications(
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getName());
        PageRequest pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        Page<NotificationResponse> notifications = notificationService.getNotifications(userId, pageable);

        PagedResponse<NotificationResponse> paged = PagedResponse.<NotificationResponse>builder()
            .content(notifications.getContent())
            .page(page)
            .size(size)
            .totalElements(notifications.getTotalElements())
            .totalPages(notifications.getTotalPages())
            .last(notifications.isLast())
            .build();

        return ResponseEntity.ok(ApiResponse.success(paged));
    }

    @GetMapping("/unread/count")
    public ResponseEntity<ApiResponse<Integer>> getUnreadCount(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        int count = notificationService.getUnreadCount(userId);
        return ResponseEntity.ok(ApiResponse.success(count));
    }

    @PutMapping("/read")
    public ResponseEntity<ApiResponse<Void>> markAsRead(Principal principal,
                                                         @Valid @RequestBody MarkReadRequest request) {
        UUID userId = UUID.fromString(principal.getName());
        notificationService.markAsRead(userId, request.getNotificationIds());
        return ResponseEntity.ok(ApiResponse.success("Notifications marked as read", null));
    }

    @PutMapping("/read/all")
    public ResponseEntity<ApiResponse<Void>> markAllAsRead(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(ApiResponse.success("All notifications marked as read", null));
    }

    @GetMapping("/preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> getPreferences(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        NotificationPreferenceResponse preferences = notificationService.getPreferences(userId);
        return ResponseEntity.ok(ApiResponse.success(preferences));
    }

    @PutMapping("/preferences")
    public ResponseEntity<ApiResponse<NotificationPreferenceResponse>> updatePreferences(
            Principal principal,
            @Valid @RequestBody UpdateNotificationPreferencesRequest request) {
        UUID userId = UUID.fromString(principal.getName());
        NotificationPreferenceResponse preferences = notificationService.updatePreferences(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Preferences updated", preferences));
    }
}
