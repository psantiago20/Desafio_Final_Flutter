package com.pitaya.gamification.repository;

import com.pitaya.gamification.entity.UserGamification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserGamificationRepository extends JpaRepository<UserGamification, UUID> {

    Optional<UserGamification> findByUserId(UUID userId);

    List<UserGamification> findAllByOrderByXpPointsDesc();
}
