package com.pitaya.user.repository;

import com.pitaya.user.entity.Follow;
import com.pitaya.user.entity.FollowId;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface FollowRepository extends JpaRepository<Follow, FollowId> {

    Page<Follow> findByFollowerId(UUID followerId, Pageable pageable);

    Page<Follow> findByFollowingId(UUID followingId, Pageable pageable);

    boolean existsByFollowerIdAndFollowingId(UUID followerId, UUID followingId);

    long countByFollowerId(UUID followerId);

    long countByFollowingId(UUID followingId);
}
