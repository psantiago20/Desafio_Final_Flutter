package com.pitaya.group.controller;

import com.pitaya.group.dto.request.CreateGroupRequest;
import com.pitaya.group.dto.request.InviteMemberRequest;
import com.pitaya.group.dto.request.UpdateGroupRequest;
import com.pitaya.group.dto.request.UpdateMemberRoleRequest;
import com.pitaya.group.dto.response.GroupResponse;
import com.pitaya.group.dto.response.GroupSummaryResponse;
import com.pitaya.group.dto.response.InviteResponse;
import com.pitaya.group.dto.response.MemberResponse;
import com.pitaya.group.service.GroupService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import jakarta.validation.Valid;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/groups")
public class GroupController {

    private final GroupService groupService;

    public GroupController(GroupService groupService) {
        this.groupService = groupService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<GroupResponse>> createGroup(
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody CreateGroupRequest request) {
        GroupResponse response = groupService.create(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Group created successfully", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<GroupResponse>> getGroup(
            @PathVariable UUID id,
            @RequestHeader(value = "X-User-Id", required = false) UUID userId) {
        GroupResponse response = groupService.findById(id, userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<GroupResponse>> updateGroup(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody UpdateGroupRequest request) {
        GroupResponse response = groupService.update(id, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Group updated successfully", response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteGroup(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        groupService.delete(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Group deleted successfully", null));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PagedResponse<GroupSummaryResponse>>> listGroups(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir) {
        Sort sort = sortDir.equalsIgnoreCase("asc") ? Sort.by(sortBy).ascending() : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        PagedResponse<GroupSummaryResponse> response = groupService.listGroups(category, search, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<GroupSummaryResponse>>> getMyGroups(
            @RequestHeader("X-User-Id") UUID userId) {
        List<GroupSummaryResponse> response = groupService.getMyGroups(userId);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PostMapping("/{id}/join")
    public ResponseEntity<ApiResponse<Void>> joinGroup(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        groupService.join(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Joined group successfully", null));
    }

    @PostMapping("/{id}/leave")
    public ResponseEntity<ApiResponse<Void>> leaveGroup(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        groupService.leave(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Left group successfully", null));
    }

    @PostMapping("/{id}/invite")
    public ResponseEntity<ApiResponse<InviteResponse>> inviteMember(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId,
            @Valid @RequestBody InviteMemberRequest request) {
        InviteResponse response = groupService.invite(id, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Invitation sent successfully", response));
    }

    @GetMapping("/{id}/members")
    public ResponseEntity<ApiResponse<PagedResponse<MemberResponse>>> getMembers(
            @PathVariable UUID id,
            @RequestParam(required = false) String role,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        PagedResponse<MemberResponse> response = groupService.getMembers(id, role, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @PutMapping("/{groupId}/members/{userId}/role")
    public ResponseEntity<ApiResponse<MemberResponse>> updateMemberRole(
            @PathVariable UUID groupId,
            @PathVariable UUID userId,
            @RequestHeader("X-User-Id") UUID requesterId,
            @Valid @RequestBody UpdateMemberRoleRequest request) {
        MemberResponse response = groupService.updateMemberRole(groupId, requesterId, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Member role updated successfully", response));
    }

    @DeleteMapping("/{groupId}/members/{userId}")
    public ResponseEntity<ApiResponse<Void>> removeMember(
            @PathVariable UUID groupId,
            @PathVariable UUID userId,
            @RequestHeader("X-User-Id") UUID requesterId) {
        groupService.removeMember(groupId, requesterId, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Member removed successfully", null));
    }

    @PostMapping("/invites/{id}/accept")
    public ResponseEntity<ApiResponse<Void>> acceptInvite(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        groupService.acceptInvite(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Invite accepted successfully", null));
    }

    @PostMapping("/invites/{id}/reject")
    public ResponseEntity<ApiResponse<Void>> rejectInvite(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID userId) {
        groupService.rejectInvite(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>success("Invite rejected successfully", null));
    }
}
