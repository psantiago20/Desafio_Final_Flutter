package com.pitaya.user.repository;

import com.pitaya.user.entity.UserInterest;
import com.pitaya.user.entity.UserInterestId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface UserInterestRepository extends JpaRepository<UserInterest, UserInterestId> {

    List<UserInterest> findByUserId(UUID userId);

    void deleteByUserId(UUID userId);
}
