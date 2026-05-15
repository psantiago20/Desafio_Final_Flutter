package com.pitaya.auth.service;

import com.pitaya.auth.dto.request.CreateUserRequest;
import com.pitaya.auth.dto.response.UserResponse;
import com.pitaya.auth.dto.response.UserSummaryResponse;
import com.pitaya.auth.entity.User;

import java.util.UUID;

public interface UserService {

    UserResponse findById(UUID id);

    UserResponse findByEmail(String email);

    UserResponse create(CreateUserRequest request);

    UserResponse update(UUID id, CreateUserRequest request);

    void delete(UUID id);

    User findUserEntityById(UUID id);

    User findUserEntityByEmail(String email);
}
