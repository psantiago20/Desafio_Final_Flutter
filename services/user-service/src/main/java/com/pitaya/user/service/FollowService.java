package com.pitaya.user.service;

import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.user.dto.response.UserSummaryResponse;

import java.util.UUID;

public interface FollowService {

    void follow(UUID followerId, UUID followingId);

    void unfollow(UUID followerId, UUID followingId);

    PagedResponse<UserSummaryResponse> getFollowers(UUID userId, int page, int size);

    PagedResponse<UserSummaryResponse> getFollowing(UUID userId, int page, int size);

    boolean isFollowing(UUID followerId, UUID followingId);
}
