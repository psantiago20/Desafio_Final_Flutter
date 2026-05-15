package com.pitaya.gamification.repository;

import com.pitaya.gamification.entity.Badge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BadgeRepository extends JpaRepository<Badge, UUID> {

    Optional<Badge> findByName(String name);

    List<Badge> findAllByOrderByXpRequired();
}
