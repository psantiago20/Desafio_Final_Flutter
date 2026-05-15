package com.pitaya.user.service;

import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import com.pitaya.user.dto.request.CreateProfileRequest;
import com.pitaya.user.dto.request.UpdateProfileRequest;
import com.pitaya.user.dto.response.ProfileResponse;
import com.pitaya.user.entity.Interest;
import com.pitaya.user.entity.Profile;
import com.pitaya.user.entity.UserInterest;
import com.pitaya.user.mapper.InterestMapper;
import com.pitaya.user.mapper.ProfileMapper;
import com.pitaya.user.repository.FollowRepository;
import com.pitaya.user.repository.InterestRepository;
import com.pitaya.user.repository.ProfileRepository;
import com.pitaya.user.repository.UserInterestRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class ProfileServiceImpl implements ProfileService {

    private static final Logger log = LoggerFactory.getLogger(ProfileServiceImpl.class);

    private final ProfileRepository profileRepository;
    private final FollowRepository followRepository;
    private final InterestRepository interestRepository;
    private final UserInterestRepository userInterestRepository;
    private final InterestMapper interestMapper;
    private final ProfileMapper profileMapper;

    public ProfileServiceImpl(ProfileRepository profileRepository,
                               FollowRepository followRepository,
                               InterestRepository interestRepository,
                               UserInterestRepository userInterestRepository,
                               InterestMapper interestMapper,
                               ProfileMapper profileMapper) {
        this.profileRepository = profileRepository;
        this.followRepository = followRepository;
        this.interestRepository = interestRepository;
        this.userInterestRepository = userInterestRepository;
        this.interestMapper = interestMapper;
        this.profileMapper = profileMapper;
    }

    @Override
    @Transactional(readOnly = true)
    public ProfileResponse getProfile(UUID userId, UUID currentUserId) {
        Profile profile = profileRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Profile not found for user: " + userId));

        ProfileResponse response = buildProfileResponse(profile);

        long followerCount = followRepository.countByFollowingId(userId);
        long followingCount = followRepository.countByFollowerId(userId);
        response.setFollowerCount(followerCount);
        response.setFollowingCount(followingCount);

        if (currentUserId != null) {
            response.setFollowing(followRepository.existsByFollowerIdAndFollowingId(currentUserId, userId));
        }

        List<UserInterest> userInterests = userInterestRepository.findByUserId(userId);
        if (!userInterests.isEmpty()) {
            List<UUID> interestIds = userInterests.stream()
                .map(UserInterest::getInterestId)
                .collect(Collectors.toList());
            List<Interest> interests = interestRepository.findAllById(interestIds);
            response.setInterests(interestMapper.toResponseList(interests));
        } else {
            response.setInterests(Collections.emptyList());
        }

        return response;
    }

    @Override
    @Transactional(readOnly = true)
    public ProfileResponse getMyProfile(UUID userId) {
        return getProfile(userId, userId);
    }

    @Override
    public ProfileResponse updateProfile(UUID userId, UpdateProfileRequest request) {
        Profile profile = profileRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Profile not found for user: " + userId));

        if (request.getAvatar() != null) profile.setAvatar(request.getAvatar());
        if (request.getBanner() != null) profile.setBanner(request.getBanner());
        if (request.getBio() != null) profile.setBio(request.getBio());
        if (request.getLocation() != null) profile.setLocation(request.getLocation());
        if (request.getInstitution() != null) profile.setInstitution(request.getInstitution());
        if (request.getCourse() != null) profile.setCourse(request.getCourse());
        if (request.getSemester() != null) profile.setSemester(request.getSemester());
        if (request.getResearchLine() != null) profile.setResearchLine(request.getResearchLine());
        if (request.getLattesUrl() != null) profile.setLattesUrl(request.getLattesUrl());
        if (request.getOrcid() != null) profile.setOrcid(request.getOrcid());
        if (request.getGithubUrl() != null) profile.setGithubUrl(request.getGithubUrl());
        if (request.getLinkedinUrl() != null) profile.setLinkedinUrl(request.getLinkedinUrl());

        profile = profileRepository.save(profile);
        log.info("Profile updated for user: {}", userId);

        return buildProfileResponse(profile);
    }

    @Override
    public String uploadAvatar(UUID userId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("File is empty");
        }

        String fileName = "avatars/" + userId + "/" + file.getOriginalFilename();
        String fileUrl = "https://storage.pitaya.com/" + fileName;

        Profile profile = profileRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Profile not found for user: " + userId));
        profile.setAvatar(fileUrl);
        profileRepository.save(profile);

        log.info("Avatar uploaded for user: {}", userId);
        return fileUrl;
    }

    @Override
    public String uploadBanner(UUID userId, MultipartFile file) {
        if (file.isEmpty()) {
            throw new BadRequestException("File is empty");
        }

        String fileName = "banners/" + userId + "/" + file.getOriginalFilename();
        String fileUrl = "https://storage.pitaya.com/" + fileName;

        Profile profile = profileRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Profile not found for user: " + userId));
        profile.setBanner(fileUrl);
        profileRepository.save(profile);

        log.info("Banner uploaded for user: {}", userId);
        return fileUrl;
    }

    @Override
    public ProfileResponse completeProfile(UUID userId, CreateProfileRequest request) {
        Profile profile = profileRepository.findByUserId(userId)
            .orElseThrow(() -> new ResourceNotFoundException("Profile not found for user: " + userId));

        profile.setInstitution(request.getInstitution());
        profile.setCourse(request.getCourse());
        profile.setSemester(request.getSemester());
        profile.setResearchLine(request.getResearchLine());
        profile.setLattesUrl(request.getLattesUrl());
        profile.setOrcid(request.getOrcid());
        profile.setGithubUrl(request.getGithubUrl());
        profile.setLinkedinUrl(request.getLinkedinUrl());
        profile.setProfileComplete(true);

        profile = profileRepository.save(profile);
        log.info("Profile completed for user: {}", userId);

        return buildProfileResponse(profile);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProfileResponse> getSuggestions(UUID userId, int limit) {
        List<UserInterest> userInterests = userInterestRepository.findByUserId(userId);

        if (userInterests.isEmpty()) {
            return Collections.emptyList();
        }

        List<UUID> interestIds = userInterests.stream()
            .map(UserInterest::getInterestId)
            .collect(Collectors.toList());

        List<UUID> followingIds = followRepository.findByFollowerId(userId, org.springframework.data.domain.Pageable.unpaged())
            .getContent()
            .stream()
            .map(f -> f.getFollowingId())
            .collect(Collectors.toList());

        List<Profile> allProfiles = profileRepository.findAll();
        List<ProfileResponse> suggestions = allProfiles.stream()
            .filter(p -> !p.getUserId().equals(userId))
            .filter(p -> !followingIds.contains(p.getUserId()))
            .limit(limit)
            .map(p -> {
                ProfileResponse r = buildProfileResponse(p);
                long fc = followRepository.countByFollowingId(p.getUserId());
                r.setFollowerCount(fc);
                return r;
            })
            .collect(Collectors.toList());

        return suggestions;
    }

    @Override
    @Transactional
    public void createProfile(UUID userId, String fullName, String username) {
        if (profileRepository.findByUserId(userId).isPresent()) {
            log.warn("Profile already exists for user: {}", userId);
            return;
        }

        Profile profile = Profile.builder()
            .userId(userId)
            .bio(null)
            .profileComplete(false)
            .build();

        profileRepository.save(profile);
        log.info("Profile created for user: {} ({})", userId, username);
    }

    private ProfileResponse buildProfileResponse(Profile profile) {
        ProfileResponse response = profileMapper.toResponse(profile);
        if (response == null) {
            response = new ProfileResponse();
        }
        response.setId(profile.getId());
        response.setUserId(profile.getUserId());
        response.setAvatar(profile.getAvatar());
        response.setBanner(profile.getBanner());
        response.setBio(profile.getBio());
        response.setLocation(profile.getLocation());
        response.setInstitution(profile.getInstitution());
        response.setCourse(profile.getCourse());
        response.setSemester(profile.getSemester());
        response.setResearchLine(profile.getResearchLine());
        response.setLattesUrl(profile.getLattesUrl());
        response.setOrcid(profile.getOrcid());
        response.setGithubUrl(profile.getGithubUrl());
        response.setLinkedinUrl(profile.getLinkedinUrl());
        response.setProfileComplete(profile.isProfileComplete());
        response.setCreatedAt(profile.getCreatedAt());
        response.setUpdatedAt(profile.getUpdatedAt());
        return response;
    }
}
