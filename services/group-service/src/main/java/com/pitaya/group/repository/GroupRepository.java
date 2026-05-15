package com.pitaya.group.repository;

import com.pitaya.group.entity.Group;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface GroupRepository extends JpaRepository<Group, UUID> {

    Page<Group> findByCategory(String category, Pageable pageable);

    Page<Group> findByNameContainingIgnoreCase(String name, Pageable pageable);

    Page<Group> findByIsActiveTrue(Pageable pageable);

    Page<Group> findByCategoryAndIsActiveTrue(String category, Pageable pageable);

    Page<Group> findByNameContainingIgnoreCaseAndIsActiveTrue(String name, Pageable pageable);
}
