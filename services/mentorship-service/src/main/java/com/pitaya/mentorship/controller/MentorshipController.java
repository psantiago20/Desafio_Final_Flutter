package com.pitaya.mentorship.controller;

import com.pitaya.mentorship.dto.request.CompleteSessionRequest;
import com.pitaya.mentorship.dto.request.CreateMentorshipRequest;
import com.pitaya.mentorship.dto.request.CreateSessionRequest;
import com.pitaya.mentorship.dto.request.FeedbackRequest;
import com.pitaya.mentorship.dto.response.MentorshipResponse;
import com.pitaya.mentorship.dto.response.MentorshipSummaryResponse;
import com.pitaya.mentorship.dto.response.SessionResponse;
import com.pitaya.mentorship.service.MentorshipService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/mentorships")
public class MentorshipController {

    private final MentorshipService mentorshipService;

    public MentorshipController(MentorshipService mentorshipService) {
        this.mentorshipService = mentorshipService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MentorshipResponse>> create(
            @Valid @RequestBody CreateMentorshipRequest request,
            Principal principal) {
        UUID menteeId = UUID.fromString(principal.getName());
        MentorshipResponse mentorship = mentorshipService.create(menteeId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Mentorship created successfully", mentorship));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MentorshipResponse>> getById(
            @PathVariable UUID id) {
        MentorshipResponse mentorship = mentorshipService.findById(id);
        return ResponseEntity.ok(ApiResponse.success(mentorship));
    }

    @PutMapping("/{id}/accept")
    public ResponseEntity<ApiResponse<MentorshipResponse>> accept(
            @PathVariable UUID id,
            Principal principal) {
        UUID mentorId = UUID.fromString(principal.getName());
        MentorshipResponse mentorship = mentorshipService.accept(id, mentorId);
        return ResponseEntity.ok(ApiResponse.success("Mentorship accepted successfully", mentorship));
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<ApiResponse<MentorshipResponse>> reject(
            @PathVariable UUID id,
            Principal principal) {
        UUID mentorId = UUID.fromString(principal.getName());
        MentorshipResponse mentorship = mentorshipService.reject(id, mentorId);
        return ResponseEntity.ok(ApiResponse.success("Mentorship rejected successfully", mentorship));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<MentorshipResponse>> complete(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        MentorshipResponse mentorship = mentorshipService.complete(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Mentorship completed successfully", mentorship));
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<MentorshipResponse>> cancel(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        MentorshipResponse mentorship = mentorshipService.cancel(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Mentorship cancelled successfully", mentorship));
    }

    @GetMapping("/mine")
    public ResponseEntity<ApiResponse<PagedResponse<MentorshipSummaryResponse>>> getMyMentorships(
            Principal principal,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status,
            @PageableDefault(sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID userId = UUID.fromString(principal.getName());
        PagedResponse<MentorshipSummaryResponse> mentorships =
            mentorshipService.getMyMentorships(userId, role, status, pageable);
        return ResponseEntity.ok(ApiResponse.success(mentorships));
    }

    @GetMapping("/available")
    public ResponseEntity<ApiResponse<PagedResponse<MentorshipSummaryResponse>>> getAvailableMentors(
            @RequestParam(required = false) String interest,
            @PageableDefault(sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PagedResponse<MentorshipSummaryResponse> mentors =
            mentorshipService.getAvailableMentors(interest, pageable);
        return ResponseEntity.ok(ApiResponse.success(mentors));
    }

    @PostMapping("/{id}/sessions")
    public ResponseEntity<ApiResponse<SessionResponse>> scheduleSession(
            @PathVariable UUID id,
            @Valid @RequestBody CreateSessionRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        SessionResponse session = mentorshipService.scheduleSession(id, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Session scheduled successfully", session));
    }

    @PutMapping("/sessions/{sessionId}/confirm")
    public ResponseEntity<ApiResponse<SessionResponse>> confirmSession(
            @PathVariable UUID sessionId,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        SessionResponse session = mentorshipService.confirmSession(sessionId, userId);
        return ResponseEntity.ok(ApiResponse.success("Session confirmed successfully", session));
    }

    @PutMapping("/sessions/{sessionId}/complete")
    public ResponseEntity<ApiResponse<SessionResponse>> completeSession(
            @PathVariable UUID sessionId,
            @Valid @RequestBody CompleteSessionRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        SessionResponse session = mentorshipService.completeSession(sessionId, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Session completed successfully", session));
    }

    @PutMapping("/sessions/{sessionId}/cancel")
    public ResponseEntity<ApiResponse<SessionResponse>> cancelSession(
            @PathVariable UUID sessionId,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        SessionResponse session = mentorshipService.cancelSession(sessionId, userId);
        return ResponseEntity.ok(ApiResponse.success("Session cancelled successfully", session));
    }

    @PostMapping("/sessions/{sessionId}/feedback")
    public ResponseEntity<ApiResponse<SessionResponse>> submitFeedback(
            @PathVariable UUID sessionId,
            @Valid @RequestBody FeedbackRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        SessionResponse session = mentorshipService.submitFeedback(sessionId, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Feedback submitted successfully", session));
    }
}
