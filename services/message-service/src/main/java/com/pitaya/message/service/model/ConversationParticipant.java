package com.pitaya.message.service.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "conversation_participants")
public class ConversationParticipant {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "conversation_id", nullable = false)
    private Conversation conversation;

    @Column(name = "user_id", nullable = false)
    private UUID userId; // Reference to user-service

    private Instant joinedAt;

    private boolean isAdmin;

    @Enumerated(EnumType.STRING)
    private NotificationSetting notificationSetting;

    private Instant lastReadAt;

    // Getters and Setters
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public Conversation getConversation() { return conversation; }
    public void setConversation(Conversation conversation) { this.conversation = conversation; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public Instant getJoinedAt() { return joinedAt; }
    public void setJoinedAt(Instant joinedAt) { this.joinedAt = joinedAt; }

    public boolean isAdmin() { return isAdmin; }
    public void setAdmin(boolean admin) { isAdmin = admin; }

    public NotificationSetting getNotificationSetting() { return notificationSetting; }
    public void setNotificationSetting(NotificationSetting notificationSetting) { this.notificationSetting = notificationSetting; }

    public Instant getLastReadAt() { return lastReadAt; }
    public void setLastReadAt(Instant lastReadAt) { this.lastReadAt = lastReadAt; }

    // Enums
    public enum NotificationSetting {
        ALL, MENTIONS, NONE
    }
}