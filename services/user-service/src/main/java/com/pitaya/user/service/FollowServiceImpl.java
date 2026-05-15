package com.pitaya.user.service;

import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import com.pitaya.user.dto.response.UserSummaryResponse;
import com.pitaya.user.entity.Follow;
import com.pitaya.user.entity.FollowId;
import com.pitaya.user.entity.Profile;
import com.pitaya.user.repository.FollowRepository;
import com.pitaya.user.repository.ProfileRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class FollowServiceImpl implements FollowService {

    private static final Logger log = LoggerFactory.getLogger(FollowServiceImpl.class);

    private final FollowRepository followRepository;
    private final ProfileRepository profileRepository;

    public FollowServiceImpl(FollowRepository followRepository,
                              ProfileRepository profileRepository) {
        this.followRepository = followRepository;
        this.profileRepository = profileRepository;
    }

    @Override
    public void follow(UUID followerId, UUID followingId) {
        if (followerId.equals(followingId)) {
            throw new BadRequestException("Cannot follow yourself");
        }

        if (!profileRepository.findByUserId(followingId).isPresent()) {
            throw new ResourceNotFoundException("User not found: " + followingId);
        }

        if (followRepository.existsByFollowerIdAndFollowingId(followerId, followingId)) {
            throw new BadRequestException("Already following this user");
        }

        FollowId followId = FollowId.builder()
            .followerId(followerId)
            .followingId(followingId)
            .build();

        Follow follow = Follow.builder()
            .id(followId)
            .build();

        followRepository.save(follow);
        log.info("User {} followed user {}", followerId, followingId);
    }

    @Override
    public void unfollow(UUID followerId, UUID followingId) {
        FollowId followId = FollowId.builder()
            .followerId(followerId)
            .followingId(followingId)
            .build();

        if (!followRepository.existsById(followId)) {
            throw new BadRequestException("Not following this user");
        }

        followRepository.deleteById(followId);
        log.info("User {} unfollowed user {}", followerId, followingId);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<UserSummaryResponse> getFollowers(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Follow> follows = followRepository.findByFollowingId(userId, pageable);

        List<UserSummaryResponse> followers = follows.getContent().stream()
            .map(f -> {
                Profile profile = profileRepository.findByUserId(f.getFollowerId()).orElse(null);
                if (profile == null) {
                    return UserSummaryResponse.builder()
                        .id(f.getFollowerId())
                        .build();
                }
                return UserSummaryResponse.builder()
                    .id(f.getFollowerId())
                    .avatar(profile.getAvatar())
                    .bio(profile.getBio())
                    .build();
            })
            .collect(Collectors.toList());

        return PagedResponse.<UserSummaryResponse>builder()
            .content(followers)
            .page(page)
            .size(size)
            .totalElements(follows.getTotalElements())
            .totalPages(follows.getTotalPages())
            .last(follows.isLast())
            .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<UserSummaryResponse> getFollowing(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Follow> follows = followRepository.findByFollowerId(userId, pageable);

        List<UserSummaryResponse> following = follows.getContent().stream()
            .map(f -> {
                Profile profile = profileRepository.findByUserId(f.getFollowingId()).orElse(null);
                if (profile == null) {
                    return UserSummaryResponse.builder()
                        .id(f.getFollowingId())
                        .build();
                }
                return UserSummaryResponse.builder()
                    .id(f.getFollowingId())
                    .avatar(profile.getAvatar())
                    .bio(profile.getBio())
                    .build();
            })
            .collect(Collectors.toList());

        return PagedResponse.<UserSummaryResponse>builder()
            .content(following)
            .page(page)
            .size(size)
            .totalElements(follows.getTotalElements())
            .totalPages(follows.getTotalPages())
            .last(follows.isLast())
            .build();
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isFollowing(UUID followerId, UUID followingId) {
        return followRepository.existsByFollowerIdAndFollowingId(followerId, followingId);
    }
}
