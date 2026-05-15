package com.pitaya.user.service;

import com.pitaya.user.dto.response.InterestResponse;

import java.util.List;
import java.util.UUID;

public interface InterestService {

    List<InterestResponse> getAllInterests();

    List<InterestResponse> updateUserInterests(UUID userId, List<String> interestNames);
}
