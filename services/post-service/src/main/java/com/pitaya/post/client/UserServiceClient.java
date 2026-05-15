package com.pitaya.post.client;

import com.pitaya.post.client.dto.UserProfileResponse;
import com.pitaya.post.client.dto.UserSummaryResponse;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.UUID;

@FeignClient(name = "user-service")
public interface UserServiceClient {

    @GetMapping("/api/v1/users/{id}")
    ApiResponse<UserProfileResponse> getUserProfile(@PathVariable UUID id);

    @GetMapping("/api/v1/users/{id}/following")
    ApiResponse<PagedResponse<UserSummaryResponse>> getFollowing(
        @PathVariable UUID id,
        @RequestParam("page") int page,
        @RequestParam("size") int size);
}
