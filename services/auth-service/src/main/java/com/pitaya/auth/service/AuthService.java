package com.pitaya.auth.service;

import com.pitaya.auth.dto.request.CreateUserRequest;
import com.pitaya.auth.dto.request.ForgotPasswordRequest;
import com.pitaya.auth.dto.request.LoginRequest;
import com.pitaya.auth.dto.request.RefreshTokenRequest;
import com.pitaya.auth.dto.request.ResetPasswordRequest;
import com.pitaya.auth.dto.response.AuthResponse;

public interface AuthService {

    AuthResponse register(CreateUserRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse refreshAccessToken(RefreshTokenRequest request);

    void logout(String refreshToken);

    void forgotPassword(ForgotPasswordRequest request);

    void resetPassword(ResetPasswordRequest request);
}
