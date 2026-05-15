package com.pitaya.gamification.repository;

import com.pitaya.gamification.entity.UserBadge;
import com.pitaya.gamification.entity.UserBadgeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserBadgeRepository extends JpaRepository<UserBadge, UserBadgeId> {

    List<UserBadge> findByUserId(UUID userId);

    boolean existsByUserIdAndBadgeId(UUID userId, UUID badgeId);

    long countByUserId(UUID userId);
}
