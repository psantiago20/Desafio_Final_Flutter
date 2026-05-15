package com.pitaya.user.service;

import com.pitaya.user.dto.request.CreateProfileRequest;
import com.pitaya.user.dto.request.UpdateProfileRequest;
import com.pitaya.user.dto.response.ProfileResponse;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

public interface ProfileService {

    ProfileResponse getProfile(UUID userId, UUID currentUserId);

    ProfileResponse getMyProfile(UUID userId);

    ProfileResponse updateProfile(UUID userId, UpdateProfileRequest request);

    String uploadAvatar(UUID userId, MultipartFile file);

    String uploadBanner(UUID userId, MultipartFile file);

    ProfileResponse completeProfile(UUID userId, CreateProfileRequest request);

    List<ProfileResponse> getSuggestions(UUID userId, int limit);

    void createProfile(UUID userId, String fullName, String username);
}
