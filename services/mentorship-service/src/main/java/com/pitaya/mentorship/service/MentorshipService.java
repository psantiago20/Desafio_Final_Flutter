package com.pitaya.mentorship.service;

import com.pitaya.mentorship.dto.request.CompleteSessionRequest;
import com.pitaya.mentorship.dto.request.CreateMentorshipRequest;
import com.pitaya.mentorship.dto.request.CreateSessionRequest;
import com.pitaya.mentorship.dto.request.FeedbackRequest;
import com.pitaya.mentorship.dto.response.MentorshipResponse;
import com.pitaya.mentorship.dto.response.MentorshipSummaryResponse;
import com.pitaya.mentorship.dto.response.SessionResponse;
import com.pitaya.shared.dto.PagedResponse;
import org.springframework.data.domain.Pageable;

import java.util.UUID;

public interface MentorshipService {

    MentorshipResponse create(UUID menteeId, CreateMentorshipRequest request);

    MentorshipResponse findById(UUID id);

    MentorshipResponse accept(UUID id, UUID mentorId);

    MentorshipResponse reject(UUID id, UUID mentorId);

    MentorshipResponse complete(UUID id, UUID userId);

    MentorshipResponse cancel(UUID id, UUID userId);

    PagedResponse<MentorshipSummaryResponse> getMyMentorships(UUID userId, String role, String status, Pageable pageable);

    PagedResponse<MentorshipSummaryResponse> getAvailableMentors(String interest, Pageable pageable);

    SessionResponse scheduleSession(UUID mentorshipId, UUID userId, CreateSessionRequest request);

    SessionResponse confirmSession(UUID sessionId, UUID userId);

    SessionResponse completeSession(UUID sessionId, UUID userId, CompleteSessionRequest request);

    SessionResponse cancelSession(UUID sessionId, UUID userId);

    SessionResponse submitFeedback(UUID sessionId, UUID userId, FeedbackRequest request);
}
