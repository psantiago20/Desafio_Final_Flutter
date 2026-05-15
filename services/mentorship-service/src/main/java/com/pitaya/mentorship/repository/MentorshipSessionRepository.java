package com.pitaya.mentorship.repository;

import com.pitaya.mentorship.entity.MentorshipSession;
import com.pitaya.mentorship.entity.SessionStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface MentorshipSessionRepository extends JpaRepository<MentorshipSession, UUID> {

    List<MentorshipSession> findByMentorshipIdOrderByScheduledAt(UUID mentorshipId);

    List<MentorshipSession> findByMentorshipIdAndStatus(UUID mentorshipId, SessionStatus status);

    int countByMentorshipId(UUID mentorshipId);
}
