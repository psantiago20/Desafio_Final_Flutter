package com.pitaya.group.service;

import com.pitaya.group.dto.request.CreateGroupRequest;
import com.pitaya.group.dto.request.InviteMemberRequest;
import com.pitaya.group.dto.request.UpdateGroupRequest;
import com.pitaya.group.dto.request.UpdateMemberRoleRequest;
import com.pitaya.group.dto.response.GroupResponse;
import com.pitaya.group.dto.response.GroupSummaryResponse;
import com.pitaya.group.dto.response.InviteResponse;
import com.pitaya.group.dto.response.MemberResponse;
import com.pitaya.shared.dto.PagedResponse;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface GroupService {

    GroupResponse create(UUID userId, CreateGroupRequest request);

    GroupResponse findById(UUID groupId, UUID userId);

    GroupResponse update(UUID groupId, UUID userId, UpdateGroupRequest request);

    void delete(UUID groupId, UUID userId);

    PagedResponse<GroupSummaryResponse> listGroups(String category, String search, Pageable pageable);

    List<GroupSummaryResponse> getMyGroups(UUID userId);

    void join(UUID groupId, UUID userId);

    void leave(UUID groupId, UUID userId);

    InviteResponse invite(UUID groupId, UUID invitedBy, InviteMemberRequest request);

    void acceptInvite(UUID inviteId, UUID userId);

    void rejectInvite(UUID inviteId, UUID userId);

    MemberResponse updateMemberRole(UUID groupId, UUID userId, UUID targetUserId, UpdateMemberRoleRequest request);

    void removeMember(UUID groupId, UUID userId, UUID targetUserId);

    PagedResponse<MemberResponse> getMembers(UUID groupId, String role, Pageable pageable);
}
