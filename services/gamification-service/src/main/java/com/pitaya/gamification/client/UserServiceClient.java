package com.pitaya.gamification.client;

import com.pitaya.gamification.client.dto.UserProfileResponse;
import com.pitaya.shared.dto.ApiResponse;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.UUID;

@FeignClient(name = "user-service")
public interface UserServiceClient {

    @GetMapping("/api/v1/users/{id}")
    ApiResponse<UserProfileResponse> getUserProfile(@PathVariable UUID id);
}
