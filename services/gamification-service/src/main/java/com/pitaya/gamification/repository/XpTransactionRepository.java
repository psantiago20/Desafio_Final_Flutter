package com.pitaya.gamification.repository;

import com.pitaya.gamification.entity.XpTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface XpTransactionRepository extends JpaRepository<XpTransaction, UUID> {

    List<XpTransaction> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Page<XpTransaction> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
}
