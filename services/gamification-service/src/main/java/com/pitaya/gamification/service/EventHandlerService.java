package com.pitaya.gamification.service;

import java.util.UUID;

public interface EventHandlerService {

    void handlePostCreated(UUID userId, String postId);

    void handleCommentAdded(UUID userId, String commentId, String postId);

    void handlePostLiked(UUID userId, String postId, String postAuthorId);

    void handleUserRegistered(UUID userId, String email, String username, String fullName);

    void handleMentorshipScheduled(UUID mentorId, UUID menteeId, String mentorshipId);
}
