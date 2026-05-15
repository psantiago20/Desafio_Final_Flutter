package com.pitaya.group.repository;

import com.pitaya.group.entity.GroupInvite;
import com.pitaya.group.enums.InviteStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface GroupInviteRepository extends JpaRepository<GroupInvite, UUID> {

    List<GroupInvite> findByInvitedUser(UUID invitedUser);

    Optional<GroupInvite> findByGroupIdAndInvitedUser(UUID groupId, UUID invitedUser);

    List<GroupInvite> findByStatus(InviteStatus status);

    List<GroupInvite> findByInvitedUserAndStatus(UUID invitedUser, InviteStatus status);

    Optional<GroupInvite> findByGroupIdAndInvitedUserAndStatus(UUID groupId, UUID invitedUser, InviteStatus status);

    List<GroupInvite> findByGroupId(UUID groupId);

    List<GroupInvite> findByGroupIdAndStatus(UUID groupId, InviteStatus status);
}
