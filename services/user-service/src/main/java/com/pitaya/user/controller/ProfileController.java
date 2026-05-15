package com.pitaya.user.controller;

import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.user.dto.request.CreateProfileRequest;
import com.pitaya.user.dto.request.UpdateInterestsRequest;
import com.pitaya.user.dto.request.UpdateProfileRequest;
import com.pitaya.user.dto.response.InterestResponse;
import com.pitaya.user.dto.response.ProfileResponse;
import com.pitaya.user.dto.response.UserSummaryResponse;
import com.pitaya.user.service.FollowService;
import com.pitaya.user.service.InterestService;
import com.pitaya.user.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
public class ProfileController {

    private final ProfileService profileService;
    private final FollowService followService;
    private final InterestService interestService;

    public ProfileController(ProfileService profileService,
                              FollowService followService,
                              InterestService interestService) {
        this.profileService = profileService;
        this.followService = followService;
        this.interestService = interestService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProfileResponse>> getUserProfile(
            @PathVariable UUID id,
            Principal principal) {
        UUID currentUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        ProfileResponse profile = profileService.getProfile(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<ProfileResponse>> getMyProfile(Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        ProfileResponse profile = profileService.getMyProfile(userId);
        return ResponseEntity.ok(ApiResponse.success(profile));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<ProfileResponse>> updateProfile(
            @Valid @RequestBody UpdateProfileRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        ProfileResponse profile = profileService.updateProfile(userId, request);
        return ResponseEntity.ok(ApiResponse.success("Profile updated successfully", profile));
    }

    @PostMapping(value = "/me/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<String>> uploadAvatar(
            @RequestParam("file") MultipartFile file,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        String avatarUrl = profileService.uploadAvatar(userId, file);
        return ResponseEntity.ok(ApiResponse.success("Avatar uploaded successfully", avatarUrl));
    }

    @PostMapping(value = "/me/banner", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<String>> uploadBanner(
            @RequestParam("file") MultipartFile file,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        String bannerUrl = profileService.uploadBanner(userId, file);
        return ResponseEntity.ok(ApiResponse.success("Banner uploaded successfully", bannerUrl));
    }

    @PutMapping("/me/interests")
    public ResponseEntity<ApiResponse<List<InterestResponse>>> updateInterests(
            @Valid @RequestBody UpdateInterestsRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        List<InterestResponse> interests = interestService.updateUserInterests(userId, request.getInterests());
        return ResponseEntity.ok(ApiResponse.success("Interests updated successfully", interests));
    }

    @GetMapping("/interests")
    public ResponseEntity<ApiResponse<List<InterestResponse>>> getAllInterests() {
        List<InterestResponse> interests = interestService.getAllInterests();
        return ResponseEntity.ok(ApiResponse.success(interests));
    }

    @GetMapping("/{id}/followers")
    public ResponseEntity<ApiResponse<PagedResponse<UserSummaryResponse>>> getFollowers(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<UserSummaryResponse> followers = followService.getFollowers(id, page, size);
        return ResponseEntity.ok(ApiResponse.success(followers));
    }

    @GetMapping("/{id}/following")
    public ResponseEntity<ApiResponse<PagedResponse<UserSummaryResponse>>> getFollowing(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<UserSummaryResponse> following = followService.getFollowing(id, page, size);
        return ResponseEntity.ok(ApiResponse.success(following));
    }

    @PostMapping("/{id}/follow")
    public ResponseEntity<ApiResponse<Void>> followUser(
            @PathVariable UUID id,
            Principal principal) {
        UUID followerId = UUID.fromString(principal.getName());
        followService.follow(followerId, id);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Followed successfully", null));
    }

    @DeleteMapping("/{id}/follow")
    public ResponseEntity<ApiResponse<Void>> unfollowUser(
            @PathVariable UUID id,
            Principal principal) {
        UUID followerId = UUID.fromString(principal.getName());
        followService.unfollow(followerId, id);
        return ResponseEntity.ok(ApiResponse.success("Unfollowed successfully", null));
    }

    @GetMapping("/me/suggestions")
    public ResponseEntity<ApiResponse<List<ProfileResponse>>> getSuggestions(
            Principal principal,
            @RequestParam(defaultValue = "10") int limit) {
        UUID userId = UUID.fromString(principal.getName());
        List<ProfileResponse> suggestions = profileService.getSuggestions(userId, limit);
        return ResponseEntity.ok(ApiResponse.success(suggestions));
    }
}
