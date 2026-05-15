package com.pitaya.user.repository;

import com.pitaya.user.entity.Interest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface InterestRepository extends JpaRepository<Interest, UUID> {

    Optional<Interest> findByName(String name);
}
