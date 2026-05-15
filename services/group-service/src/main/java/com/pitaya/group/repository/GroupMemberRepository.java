package com.pitaya.group.repository;

import com.pitaya.group.entity.GroupMember;
import com.pitaya.group.enums.MemberRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GroupMemberRepository extends JpaRepository<GroupMember, UUID> {

    List<GroupMember> findByGroupId(UUID groupId);

    List<GroupMember> findByUserId(UUID userId);

    Optional<GroupMember> findByGroupIdAndUserId(UUID groupId, UUID userId);

    List<GroupMember> findByGroupIdAndRole(UUID groupId, MemberRole role);

    Page<GroupMember> findByGroupId(UUID groupId, Pageable pageable);

    Page<GroupMember> findByGroupIdAndRole(UUID groupId, MemberRole role, Pageable pageable);

    boolean existsByGroupIdAndUserId(UUID groupId, UUID userId);

    long countByGroupId(UUID groupId);
}
