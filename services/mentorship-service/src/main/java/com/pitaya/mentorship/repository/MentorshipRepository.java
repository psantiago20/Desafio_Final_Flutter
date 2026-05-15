package com.pitaya.mentorship.repository;

import com.pitaya.mentorship.entity.Mentorship;
import com.pitaya.mentorship.entity.MentorshipStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface MentorshipRepository extends JpaRepository<Mentorship, UUID> {

    Page<Mentorship> findByMentorId(UUID mentorId, Pageable pageable);

    Page<Mentorship> findByMenteeId(UUID menteeId, Pageable pageable);

    Page<Mentorship> findByStatus(MentorshipStatus status, Pageable pageable);

    Page<Mentorship> findByMentorIdAndStatus(UUID mentorId, MentorshipStatus status, Pageable pageable);

    Page<Mentorship> findByMenteeIdAndStatus(UUID menteeId, MentorshipStatus status, Pageable pageable);
}
