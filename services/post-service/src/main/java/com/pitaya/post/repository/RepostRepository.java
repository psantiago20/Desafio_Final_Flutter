package com.pitaya.post.repository;

import com.pitaya.post.entity.Repost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface RepostRepository extends JpaRepository<Repost, UUID> {

    Optional<Repost> findByUserIdAndOriginalPostId(UUID userId, UUID originalPostId);

    boolean existsByUserIdAndOriginalPostId(UUID userId, UUID originalPostId);

    long countByOriginalPostId(UUID originalPostId);

    void deleteByUserIdAndOriginalPostId(UUID userId, UUID originalPostId);

    void deleteByOriginalPostId(UUID originalPostId);
}
