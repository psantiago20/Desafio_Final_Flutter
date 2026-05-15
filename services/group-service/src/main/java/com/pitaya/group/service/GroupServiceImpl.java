package com.pitaya.group.service;

import com.pitaya.group.dto.request.CreateGroupRequest;
import com.pitaya.group.dto.request.InviteMemberRequest;
import com.pitaya.group.dto.request.UpdateGroupRequest;
import com.pitaya.group.dto.request.UpdateMemberRoleRequest;
import com.pitaya.group.dto.response.GroupResponse;
import com.pitaya.group.dto.response.GroupSummaryResponse;
import com.pitaya.group.dto.response.InviteResponse;
import com.pitaya.group.dto.response.MemberResponse;
import com.pitaya.group.entity.Group;
import com.pitaya.group.entity.GroupInvite;
import com.pitaya.group.entity.GroupMember;
import com.pitaya.group.enums.GroupVisibility;
import com.pitaya.group.enums.InviteStatus;
import com.pitaya.group.enums.MemberRole;
import com.pitaya.group.event.producer.GroupEventProducer;
import com.pitaya.group.mapper.GroupMapper;
import com.pitaya.group.mapper.GroupMemberMapper;
import com.pitaya.group.repository.GroupInviteRepository;
import com.pitaya.group.repository.GroupMemberRepository;
import com.pitaya.group.repository.GroupRepository;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ForbiddenException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class GroupServiceImpl implements GroupService {

    private static final Logger log = LoggerFactory.getLogger(GroupServiceImpl.class);

    private final GroupRepository groupRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final GroupInviteRepository groupInviteRepository;
    private final GroupEventProducer eventProducer;
    private final GroupMapper groupMapper;
    private final GroupMemberMapper groupMemberMapper;

    public GroupServiceImpl(GroupRepository groupRepository,
                            GroupMemberRepository groupMemberRepository,
                            GroupInviteRepository groupInviteRepository,
                            GroupEventProducer eventProducer,
                            GroupMapper groupMapper,
                            GroupMemberMapper groupMemberMapper) {
        this.groupRepository = groupRepository;
        this.groupMemberRepository = groupMemberRepository;
        this.groupInviteRepository = groupInviteRepository;
        this.eventProducer = eventProducer;
        this.groupMapper = groupMapper;
        this.groupMemberMapper = groupMemberMapper;
    }

    @Override
    public GroupResponse create(UUID userId, CreateGroupRequest request) {
        Group group = groupMapper.toEntity(request);
        group.setOwnerId(userId);
        if (group.getVisibility() == null) {
            group.setVisibility(GroupVisibility.PUBLIC);
        }
        group = groupRepository.save(group);

        GroupMember owner = GroupMember.builder()
            .groupId(group.getId())
            .userId(userId)
            .role(MemberRole.OWNER)
            .build();
        groupMemberRepository.save(owner);

        eventProducer.publishGroupCreatedEvent(group);

        log.info("Group created: {} by user: {}", group.getId(), userId);
        return enrichGroupResponse(group, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public GroupResponse findById(UUID groupId, UUID userId) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));
        return enrichGroupResponse(group, userId);
    }

    @Override
    public GroupResponse update(UUID groupId, UUID userId, UpdateGroupRequest request) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        validateAdminAccess(groupId, userId);

        if (request.getName() != null) {
            group.setName(request.getName());
        }
        if (request.getDescription() != null) {
            group.setDescription(request.getDescription());
        }
        if (request.getBannerUrl() != null) {
            group.setBannerUrl(request.getBannerUrl());
        }
        if (request.getCategory() != null) {
            group.setCategory(request.getCategory());
        }
        if (request.getVisibility() != null) {
            group.setVisibility(request.getVisibility());
        }
        if (request.getIsActive() != null) {
            group.setActive(request.getIsActive());
        }

        group = groupRepository.save(group);
        log.info("Group updated: {} by user: {}", groupId, userId);
        return enrichGroupResponse(group, userId);
    }

    @Override
    public void delete(UUID groupId, UUID userId) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        if (!group.getOwnerId().equals(userId)) {
            throw new ForbiddenException("Only the group owner can delete the group");
        }

        groupMemberRepository.deleteAll(groupMemberRepository.findByGroupId(groupId));
        groupRepository.delete(group);

        log.info("Group deleted: {} by user: {}", groupId, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<GroupSummaryResponse> listGroups(String category, String search, Pageable pageable) {
        Page<Group> groups;
        if (search != null && !search.isBlank()) {
            groups = groupRepository.findByNameContainingIgnoreCaseAndIsActiveTrue(search, pageable);
        } else if (category != null && !category.isBlank()) {
            groups = groupRepository.findByCategoryAndIsActiveTrue(category, pageable);
        } else {
            groups = groupRepository.findByIsActiveTrue(pageable);
        }

        List<GroupSummaryResponse> content = groups.getContent().stream()
            .map(groupMapper::toSummaryResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, groups, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public List<GroupSummaryResponse> getMyGroups(UUID userId) {
        List<GroupMember> memberships = groupMemberRepository.findByUserId(userId);
        return memberships.stream()
            .map(member -> {
                Group group = groupRepository.findById(member.getGroupId())
                    .orElse(null);
                if (group == null) return null;
                return groupMapper.toSummaryResponse(group);
            })
            .filter(s -> s != null)
            .collect(Collectors.toList());
    }

    @Override
    public void join(UUID groupId, UUID userId) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        if (group.getVisibility() != GroupVisibility.PUBLIC) {
            throw new ForbiddenException("This group is not open for public joining");
        }

        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, userId)) {
            throw new BadRequestException("You are already a member of this group");
        }

        GroupMember member = GroupMember.builder()
            .groupId(groupId)
            .userId(userId)
            .role(MemberRole.MEMBER)
            .build();
        groupMemberRepository.save(member);

        group.setMemberCount(group.getMemberCount() + 1);
        groupRepository.save(group);

        log.info("User {} joined group: {}", userId, groupId);
    }

    @Override
    public void leave(UUID groupId, UUID userId) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        GroupMember membership = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new BadRequestException("You are not a member of this group"));

        if (membership.getRole() == MemberRole.OWNER) {
            throw new BadRequestException("Group owner cannot leave the group. Transfer ownership first or delete the group.");
        }

        groupMemberRepository.delete(membership);

        group.setMemberCount(Math.max(0, group.getMemberCount() - 1));
        groupRepository.save(group);

        log.info("User {} left group: {}", userId, groupId);
    }

    @Override
    public InviteResponse invite(UUID groupId, UUID invitedBy, InviteMemberRequest request) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        validateInvitePermission(groupId, invitedBy);

        UUID invitedUser = request.getUserId();

        if (groupMemberRepository.existsByGroupIdAndUserId(groupId, invitedUser)) {
            throw new BadRequestException("User is already a member of this group");
        }

        Optional<GroupInvite> existingInvite = groupInviteRepository
            .findByGroupIdAndInvitedUserAndStatus(groupId, invitedUser, InviteStatus.PENDING);
        if (existingInvite.isPresent()) {
            throw new BadRequestException("User has already been invited to this group");
        }

        GroupInvite invite = GroupInvite.builder()
            .groupId(groupId)
            .invitedBy(invitedBy)
            .invitedUser(invitedUser)
            .status(InviteStatus.PENDING)
            .build();
        invite = groupInviteRepository.save(invite);

        log.info("User {} invited user {} to group: {}", invitedBy, invitedUser, groupId);
        return buildInviteResponse(invite, group.getName(), invitedBy.toString(), invitedUser.toString());
    }

    @Override
    public void acceptInvite(UUID inviteId, UUID userId) {
        GroupInvite invite = groupInviteRepository.findById(inviteId)
            .orElseThrow(() -> new ResourceNotFoundException("Invite", "id", inviteId));

        if (!invite.getInvitedUser().equals(userId)) {
            throw new ForbiddenException("This invite is not for you");
        }
        if (invite.getStatus() != InviteStatus.PENDING) {
            throw new BadRequestException("This invite has already been " + invite.getStatus().name().toLowerCase());
        }

        invite.setStatus(InviteStatus.ACCEPTED);
        invite.setRespondedAt(LocalDateTime.now());
        groupInviteRepository.save(invite);

        if (!groupMemberRepository.existsByGroupIdAndUserId(invite.getGroupId(), userId)) {
            GroupMember member = GroupMember.builder()
                .groupId(invite.getGroupId())
                .userId(userId)
                .role(MemberRole.MEMBER)
                .build();
            groupMemberRepository.save(member);

            Group group = groupRepository.findById(invite.getGroupId())
                .orElseThrow(() -> new ResourceNotFoundException("Group", "id", invite.getGroupId()));
            group.setMemberCount(group.getMemberCount() + 1);
            groupRepository.save(group);
        }

        log.info("User {} accepted invite {} to group: {}", userId, inviteId, invite.getGroupId());
    }

    @Override
    public void rejectInvite(UUID inviteId, UUID userId) {
        GroupInvite invite = groupInviteRepository.findById(inviteId)
            .orElseThrow(() -> new ResourceNotFoundException("Invite", "id", inviteId));

        if (!invite.getInvitedUser().equals(userId)) {
            throw new ForbiddenException("This invite is not for you");
        }
        if (invite.getStatus() != InviteStatus.PENDING) {
            throw new BadRequestException("This invite has already been " + invite.getStatus().name().toLowerCase());
        }

        invite.setStatus(InviteStatus.REJECTED);
        invite.setRespondedAt(LocalDateTime.now());
        groupInviteRepository.save(invite);

        log.info("User {} rejected invite {} to group: {}", userId, inviteId, invite.getGroupId());
    }

    @Override
    public MemberResponse updateMemberRole(UUID groupId, UUID userId, UUID targetUserId, UpdateMemberRoleRequest request) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        validateAdminAccess(groupId, userId);

        GroupMember targetMember = groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow(() -> new ResourceNotFoundException("GroupMember", "userId", targetUserId));

        if (targetMember.getRole() == MemberRole.OWNER) {
            throw new ForbiddenException("Cannot change the role of the group owner");
        }

        MemberRole requesterRole = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("GroupMember", "userId", userId))
            .getRole();

        if (requesterRole == MemberRole.ADMIN && targetMember.getRole() == MemberRole.ADMIN) {
            throw new ForbiddenException("Admins cannot modify other admins");
        }

        if (request.getRole() == MemberRole.OWNER) {
            throw new BadRequestException("Cannot set a member as owner. Transfer ownership instead.");
        }

        targetMember.setRole(request.getRole());
        groupMemberRepository.save(targetMember);

        log.info("User {} role changed to {} in group: {}", targetUserId, request.getRole(), groupId);
        return enrichMemberResponse(targetMember);
    }

    @Override
    public void removeMember(UUID groupId, UUID userId, UUID targetUserId) {
        Group group = groupRepository.findById(groupId)
            .orElseThrow(() -> new ResourceNotFoundException("Group", "id", groupId));

        validateAdminAccess(groupId, userId);

        if (group.getOwnerId().equals(targetUserId)) {
            throw new ForbiddenException("Cannot remove the group owner");
        }

        GroupMember targetMember = groupMemberRepository.findByGroupIdAndUserId(groupId, targetUserId)
            .orElseThrow(() -> new ResourceNotFoundException("GroupMember", "userId", targetUserId));

        MemberRole requesterRole = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("GroupMember", "userId", userId))
            .getRole();

        if (requesterRole == MemberRole.ADMIN && targetMember.getRole() == MemberRole.ADMIN) {
            throw new ForbiddenException("Admins cannot remove other admins");
        }

        groupMemberRepository.delete(targetMember);

        group.setMemberCount(Math.max(0, group.getMemberCount() - 1));
        groupRepository.save(group);

        log.info("User {} removed from group: {} by user: {}", targetUserId, groupId, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<MemberResponse> getMembers(UUID groupId, String role, Pageable pageable) {
        if (!groupRepository.existsById(groupId)) {
            throw new ResourceNotFoundException("Group", "id", groupId);
        }

        Page<GroupMember> members;
        if (role != null && !role.isBlank()) {
            MemberRole memberRole;
            try {
                memberRole = MemberRole.valueOf(role.toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new BadRequestException("Invalid role: " + role);
            }
            members = groupMemberRepository.findByGroupIdAndRole(groupId, memberRole, pageable);
        } else {
            members = groupMemberRepository.findByGroupId(groupId, pageable);
        }

        List<MemberResponse> content = members.getContent().stream()
            .map(this::enrichMemberResponse)
            .collect(Collectors.toList());

        return buildPagedResponse(content, members, pageable);
    }

    private void validateAdminAccess(UUID groupId, UUID userId) {
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new ForbiddenException("You are not a member of this group"));

        if (member.getRole() != MemberRole.OWNER && member.getRole() != MemberRole.ADMIN) {
            throw new ForbiddenException("You do not have permission to perform this action");
        }
    }

    private void validateInvitePermission(UUID groupId, UUID userId) {
        GroupMember member = groupMemberRepository.findByGroupIdAndUserId(groupId, userId)
            .orElseThrow(() -> new ForbiddenException("You are not a member of this group"));

        if (member.getRole() == MemberRole.MEMBER) {
            throw new ForbiddenException("Only admins, moderators and the owner can invite members");
        }
    }

    private GroupResponse enrichGroupResponse(Group group, UUID currentUserId) {
        GroupResponse response = groupMapper.toResponse(group);
        if (response == null) {
            response = new GroupResponse();
        }
        final GroupResponse finalResponse = response;
        finalResponse.setId(group.getId());
        finalResponse.setName(group.getName());
        finalResponse.setDescription(group.getDescription());
        finalResponse.setBannerUrl(group.getBannerUrl());
        finalResponse.setCategory(group.getCategory());
        finalResponse.setVisibility(group.getVisibility());
        finalResponse.setOwnerId(group.getOwnerId());
        finalResponse.setMemberCount(group.getMemberCount());
        finalResponse.setActive(group.isActive());
        finalResponse.setCreatedAt(group.getCreatedAt());
        finalResponse.setUpdatedAt(group.getUpdatedAt());

        if (currentUserId != null) {
            Optional<GroupMember> membership = groupMemberRepository
                .findByGroupIdAndUserId(group.getId(), currentUserId);
            finalResponse.setMember(membership.isPresent());
            membership.ifPresent(m -> finalResponse.setMembershipRole(m.getRole().name()));
        }

        return finalResponse;
    }

    private <T> PagedResponse<T> buildPagedResponse(List<T> content, Page<?> page, Pageable pageable) {
        return PagedResponse.<T>builder()
            .content(content)
            .page(pageable.getPageNumber())
            .size(pageable.getPageSize())
            .totalElements(page.getTotalElements())
            .totalPages(page.getTotalPages())
            .last(page.isLast())
            .build();
    }

    private InviteResponse buildInviteResponse(GroupInvite invite, String groupName,
                                                String invitedByDisplayName, String invitedUserDisplayName) {
        return InviteResponse.builder()
            .id(invite.getId())
            .groupId(invite.getGroupId())
            .groupName(groupName)
            .invitedBy(invite.getInvitedBy())
            .invitedByDisplayName(invitedByDisplayName)
            .invitedUser(invite.getInvitedUser())
            .invitedUserDisplayName(invitedUserDisplayName)
            .status(invite.getStatus())
            .createdAt(invite.getCreatedAt())
            .respondedAt(invite.getRespondedAt())
            .build();
    }

    private MemberResponse enrichMemberResponse(GroupMember member) {
        MemberResponse response = groupMemberMapper.toMemberResponse(member);
        if (response == null) {
            response = new MemberResponse();
        }
        response.setId(member.getId());
        response.setUserId(member.getUserId());
        response.setRole(member.getRole());
        response.setJoinedAt(member.getJoinedAt());
        return response;
    }
}
