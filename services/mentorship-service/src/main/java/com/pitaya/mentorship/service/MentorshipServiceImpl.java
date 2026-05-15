package com.pitaya.mentorship.service;

import com.pitaya.mentorship.dto.request.CompleteSessionRequest;
import com.pitaya.mentorship.dto.request.CreateMentorshipRequest;
import com.pitaya.mentorship.dto.request.CreateSessionRequest;
import com.pitaya.mentorship.dto.request.FeedbackRequest;
import com.pitaya.mentorship.dto.response.MentorshipResponse;
import com.pitaya.mentorship.dto.response.MentorshipSummaryResponse;
import com.pitaya.mentorship.dto.response.SessionResponse;
import com.pitaya.mentorship.entity.Mentorship;
import com.pitaya.mentorship.entity.MentorshipSession;
import com.pitaya.mentorship.entity.MentorshipStatus;
import com.pitaya.mentorship.entity.SessionStatus;
import com.pitaya.mentorship.event.producer.MentorshipEventProducer;
import com.pitaya.mentorship.mapper.MentorshipMapper;
import com.pitaya.mentorship.mapper.MentorshipSessionMapper;
import com.pitaya.mentorship.repository.MentorshipRepository;
import com.pitaya.mentorship.repository.MentorshipSessionRepository;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ForbiddenException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class MentorshipServiceImpl implements MentorshipService {

    private static final Logger log = LoggerFactory.getLogger(MentorshipServiceImpl.class);

    private final MentorshipRepository mentorshipRepository;
    private final MentorshipSessionRepository sessionRepository;
    private final MentorshipEventProducer eventProducer;
    private final MentorshipMapper mentorshipMapper;
    private final MentorshipSessionMapper sessionMapper;

    public MentorshipServiceImpl(MentorshipRepository mentorshipRepository,
                                  MentorshipSessionRepository sessionRepository,
                                  MentorshipEventProducer eventProducer,
                                  MentorshipMapper mentorshipMapper,
                                  MentorshipSessionMapper sessionMapper) {
        this.mentorshipRepository = mentorshipRepository;
        this.sessionRepository = sessionRepository;
        this.eventProducer = eventProducer;
        this.mentorshipMapper = mentorshipMapper;
        this.sessionMapper = sessionMapper;
    }

    @Override
    public MentorshipResponse create(UUID menteeId, CreateMentorshipRequest request) {
        Mentorship mentorship = mentorshipMapper.toEntity(request);
        mentorship.setMentorId(request.getMentorId());
        mentorship.setMenteeId(menteeId);
        mentorship.setStatus(MentorshipStatus.PENDING);
        mentorship = mentorshipRepository.save(mentorship);

        log.info("Mentorship created: {} (mentor: {}, mentee: {})",
            mentorship.getId(), request.getMentorId(), menteeId);

        return enrichMentorshipResponse(mentorship);
    }

    @Override
    @Transactional(readOnly = true)
    public MentorshipResponse findById(UUID id) {
        Mentorship mentorship = findMentorshipOrThrow(id);
        return enrichMentorshipResponse(mentorship);
    }

    @Override
    public MentorshipResponse accept(UUID id, UUID mentorId) {
        Mentorship mentorship = findMentorshipOrThrow(id);

        if (mentorship.getStatus() != MentorshipStatus.PENDING) {
            throw new BadRequestException("Mentorship is not in PENDING status");
        }
        if (!mentorship.getMentorId().equals(mentorId)) {
            throw new ForbiddenException("Only the assigned mentor can accept this mentorship");
        }

        mentorship.setStatus(MentorshipStatus.ACTIVE);
        mentorship.setStartDate(LocalDateTime.now());
        mentorship = mentorshipRepository.save(mentorship);

        log.info("Mentorship accepted: {} by mentor: {}", id, mentorId);
        return enrichMentorshipResponse(mentorship);
    }

    @Override
    public MentorshipResponse reject(UUID id, UUID mentorId) {
        Mentorship mentorship = findMentorshipOrThrow(id);

        if (mentorship.getStatus() != MentorshipStatus.PENDING) {
            throw new BadRequestException("Mentorship is not in PENDING status");
        }
        if (!mentorship.getMentorId().equals(mentorId)) {
            throw new ForbiddenException("Only the assigned mentor can reject this mentorship");
        }

        mentorship.setStatus(MentorshipStatus.CANCELLED);
        mentorship = mentorshipRepository.save(mentorship);

        log.info("Mentorship rejected: {} by mentor: {}", id, mentorId);
        return enrichMentorshipResponse(mentorship);
    }

    @Override
    public MentorshipResponse complete(UUID id, UUID userId) {
        Mentorship mentorship = findMentorshipOrThrow(id);

        if (mentorship.getStatus() != MentorshipStatus.ACTIVE) {
            throw new BadRequestException("Mentorship is not in ACTIVE status");
        }
        if (!mentorship.getMentorId().equals(userId) && !mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("You are not part of this mentorship");
        }

        mentorship.setStatus(MentorshipStatus.COMPLETED);
        mentorship.setEndDate(LocalDateTime.now());
        mentorship = mentorshipRepository.save(mentorship);

        log.info("Mentorship completed: {} by user: {}", id, userId);
        return enrichMentorshipResponse(mentorship);
    }

    @Override
    public MentorshipResponse cancel(UUID id, UUID userId) {
        Mentorship mentorship = findMentorshipOrThrow(id);

        if (mentorship.getStatus() == MentorshipStatus.COMPLETED) {
            throw new BadRequestException("Cannot cancel a completed mentorship");
        }
        if (!mentorship.getMentorId().equals(userId) && !mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("You are not part of this mentorship");
        }

        mentorship.setStatus(MentorshipStatus.CANCELLED);
        mentorship = mentorshipRepository.save(mentorship);

        log.info("Mentorship cancelled: {} by user: {}", id, userId);
        return enrichMentorshipResponse(mentorship);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MentorshipSummaryResponse> getMyMentorships(UUID userId, String role, String status, Pageable pageable) {
        Page<Mentorship> mentorships;
        MentorshipStatus mentorshipStatus = status != null ? MentorshipStatus.valueOf(status.toUpperCase()) : null;

        if ("mentor".equalsIgnoreCase(role)) {
            if (mentorshipStatus != null) {
                mentorships = mentorshipRepository.findByMentorIdAndStatus(userId, mentorshipStatus, pageable);
            } else {
                mentorships = mentorshipRepository.findByMentorId(userId, pageable);
            }
        } else if ("mentee".equalsIgnoreCase(role)) {
            if (mentorshipStatus != null) {
                mentorships = mentorshipRepository.findByMenteeIdAndStatus(userId, mentorshipStatus, pageable);
            } else {
                mentorships = mentorshipRepository.findByMenteeId(userId, pageable);
            }
        } else {
            throw new BadRequestException("Invalid role: must be 'mentor' or 'mentee'");
        }

        List<MentorshipSummaryResponse> content = mentorships.getContent().stream()
            .map(this::enrichSummaryResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, mentorships, pageable.getPageNumber(), pageable.getPageSize());
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MentorshipSummaryResponse> getAvailableMentors(String interest, Pageable pageable) {
        return PagedResponse.<MentorshipSummaryResponse>builder()
            .content(Collections.emptyList())
            .page(pageable.getPageNumber())
            .size(pageable.getPageSize())
            .totalElements(0)
            .totalPages(0)
            .last(true)
            .build();
    }

    @Override
    public SessionResponse scheduleSession(UUID mentorshipId, UUID userId, CreateSessionRequest request) {
        Mentorship mentorship = findMentorshipOrThrow(mentorshipId);

        if (mentorship.getStatus() != MentorshipStatus.ACTIVE) {
            throw new BadRequestException("Mentorship is not active");
        }
        if (!mentorship.getMentorId().equals(userId) && !mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("You are not part of this mentorship");
        }

        if (mentorship.getMaxSessions() != null) {
            int currentSessions = sessionRepository.countByMentorshipId(mentorshipId);
            if (currentSessions >= mentorship.getMaxSessions()) {
                throw new BadRequestException("Maximum number of sessions reached");
            }
        }

        MentorshipSession session = sessionMapper.toEntity(request);
        session.setMentorshipId(mentorshipId);
        session.setStatus(SessionStatus.SCHEDULED);
        session = sessionRepository.save(session);

        eventProducer.publishMentorshipScheduledEvent(
            mentorshipId, mentorship.getMentorId(), mentorship.getMenteeId(),
            session.getScheduledAt(),
            session.getScheduledAt().plusMinutes(session.getDurationMinutes()),
            session.getTitle(),
            session.getStatus().name()
        );

        log.info("Session scheduled: {} for mentorship: {}", session.getId(), mentorshipId);
        return sessionMapper.toResponse(session);
    }

    @Override
    public SessionResponse confirmSession(UUID sessionId, UUID userId) {
        MentorshipSession session = findSessionOrThrow(sessionId);

        if (session.getStatus() != SessionStatus.SCHEDULED) {
            throw new BadRequestException("Session is not in SCHEDULED status");
        }

        Mentorship mentorship = findMentorshipOrThrow(session.getMentorshipId());
        if (!mentorship.getMentorId().equals(userId) && !mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("You are not part of this mentorship");
        }

        session.setStatus(SessionStatus.CONFIRMED);
        session = sessionRepository.save(session);

        log.info("Session confirmed: {} by user: {}", sessionId, userId);
        return sessionMapper.toResponse(session);
    }

    @Override
    public SessionResponse completeSession(UUID sessionId, UUID userId, CompleteSessionRequest request) {
        MentorshipSession session = findSessionOrThrow(sessionId);

        Mentorship mentorship = findMentorshipOrThrow(session.getMentorshipId());
        if (!mentorship.getMentorId().equals(userId)) {
            throw new ForbiddenException("Only the mentor can complete a session");
        }

        if (session.getStatus() != SessionStatus.CONFIRMED && session.getStatus() != SessionStatus.IN_PROGRESS) {
            throw new BadRequestException("Session must be CONFIRMED or IN_PROGRESS to complete");
        }

        session.setStatus(SessionStatus.COMPLETED);
        if (request.getMentorNotes() != null) {
            session.setMentorNotes(request.getMentorNotes());
        }
        session = sessionRepository.save(session);

        log.info("Session completed: {} by mentor: {}", sessionId, userId);
        return sessionMapper.toResponse(session);
    }

    @Override
    public SessionResponse cancelSession(UUID sessionId, UUID userId) {
        MentorshipSession session = findSessionOrThrow(sessionId);

        if (session.getStatus() == SessionStatus.COMPLETED) {
            throw new BadRequestException("Cannot cancel a completed session");
        }

        Mentorship mentorship = findMentorshipOrThrow(session.getMentorshipId());
        if (!mentorship.getMentorId().equals(userId) && !mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("You are not part of this mentorship");
        }

        session.setStatus(SessionStatus.CANCELLED);
        session = sessionRepository.save(session);

        log.info("Session cancelled: {} by user: {}", sessionId, userId);
        return sessionMapper.toResponse(session);
    }

    @Override
    public SessionResponse submitFeedback(UUID sessionId, UUID userId, FeedbackRequest request) {
        MentorshipSession session = findSessionOrThrow(sessionId);

        if (session.getStatus() != SessionStatus.COMPLETED) {
            throw new BadRequestException("Can only submit feedback for completed sessions");
        }

        Mentorship mentorship = findMentorshipOrThrow(session.getMentorshipId());
        if (!mentorship.getMenteeId().equals(userId)) {
            throw new ForbiddenException("Only the mentee can submit feedback");
        }

        session.setRating(request.getRating());
        session.setMenteeFeedback(request.getFeedback());
        session = sessionRepository.save(session);

        log.info("Feedback submitted for session: {} by mentee: {}", sessionId, userId);
        return sessionMapper.toResponse(session);
    }

    private Mentorship findMentorshipOrThrow(UUID id) {
        return mentorshipRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Mentorship", "id", id));
    }

    private MentorshipSession findSessionOrThrow(UUID sessionId) {
        return sessionRepository.findById(sessionId)
            .orElseThrow(() -> new ResourceNotFoundException("MentorshipSession", "id", sessionId));
    }

    private MentorshipResponse enrichMentorshipResponse(Mentorship mentorship) {
        MentorshipResponse response = mentorshipMapper.toResponse(mentorship);
        if (response == null) {
            response = new MentorshipResponse();
        }
        response.setId(mentorship.getId());
        response.setMentorId(mentorship.getMentorId());
        response.setMenteeId(mentorship.getMenteeId());
        response.setTitle(mentorship.getTitle());
        response.setDescription(mentorship.getDescription());
        response.setStatus(mentorship.getStatus());
        response.setStartDate(mentorship.getStartDate());
        response.setEndDate(mentorship.getEndDate());
        response.setMaxSessions(mentorship.getMaxSessions());
        response.setCreatedAt(mentorship.getCreatedAt());
        response.setUpdatedAt(mentorship.getUpdatedAt());
        response.setSessionCount(sessionRepository.countByMentorshipId(mentorship.getId()));
        return response;
    }

    private MentorshipSummaryResponse enrichSummaryResponse(Mentorship mentorship) {
        MentorshipSummaryResponse response = mentorshipMapper.toSummaryResponse(mentorship);
        if (response == null) {
            response = new MentorshipSummaryResponse();
        }
        response.setId(mentorship.getId());
        response.setMentorId(mentorship.getMentorId());
        response.setMenteeId(mentorship.getMenteeId());
        response.setTitle(mentorship.getTitle());
        response.setStatus(mentorship.getStatus());
        response.setStartDate(mentorship.getStartDate());
        response.setEndDate(mentorship.getEndDate());
        response.setCreatedAt(mentorship.getCreatedAt());
        response.setSessionCount(sessionRepository.countByMentorshipId(mentorship.getId()));
        return response;
    }

    private <T> PagedResponse<T> buildPagedResponse(List<T> content, Page<?> page, int pageNo, int size) {
        return PagedResponse.<T>builder()
            .content(content)
            .page(pageNo)
            .size(size)
            .totalElements(page.getTotalElements())
            .totalPages(page.getTotalPages())
            .last(page.isLast())
            .build();
    }
}
