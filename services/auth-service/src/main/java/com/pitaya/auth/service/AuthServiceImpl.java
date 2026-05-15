package com.pitaya.auth.service;

import com.pitaya.auth.dto.request.CreateUserRequest;
import com.pitaya.auth.dto.request.ForgotPasswordRequest;
import com.pitaya.auth.dto.request.LoginRequest;
import com.pitaya.auth.dto.request.RefreshTokenRequest;
import com.pitaya.auth.dto.request.ResetPasswordRequest;
import com.pitaya.auth.dto.response.AuthResponse;
import com.pitaya.auth.dto.response.UserSummaryResponse;
import com.pitaya.auth.entity.PasswordResetToken;
import com.pitaya.auth.entity.RefreshToken;
import com.pitaya.auth.entity.User;
import com.pitaya.auth.event.producer.AuthEventProducer;
import com.pitaya.auth.mapper.UserMapper;
import com.pitaya.auth.repository.PasswordResetTokenRepository;
import com.pitaya.auth.repository.UserRepository;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.UnauthorizedException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@Transactional(readOnly = true)
public class AuthServiceImpl implements AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthServiceImpl.class);
    private static final long PASSWORD_RESET_TOKEN_EXPIRATION_HOURS = 24;

    private final UserRepository userRepository;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenService refreshTokenService;
    private final AuthEventProducer authEventProducer;
    private final UserMapper userMapper;

    public AuthServiceImpl(UserRepository userRepository,
                           PasswordResetTokenRepository passwordResetTokenRepository,
                           PasswordEncoder passwordEncoder,
                           JwtTokenProvider jwtTokenProvider,
                           RefreshTokenService refreshTokenService,
                           AuthEventProducer authEventProducer,
                           UserMapper userMapper) {
        this.userRepository = userRepository;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.refreshTokenService = refreshTokenService;
        this.authEventProducer = authEventProducer;
        this.userMapper = userMapper;
    }

    @Override
    @Transactional
    public AuthResponse register(CreateUserRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email is already registered");
        }
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username is already taken");
        }
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Passwords do not match");
        }

        User user = User.builder()
            .email(request.getEmail())
            .password(passwordEncoder.encode(request.getPassword()))
            .fullName(request.getFullName())
            .username(request.getUsername())
            .role(request.getRole())
            .birthDate(request.getBirthDate())
            .enabled(true)
            .emailVerified(false)
            .build();

        User savedUser = userRepository.save(user);

        authEventProducer.publishUserRegisteredEvent(savedUser);

        String accessToken = jwtTokenProvider.generateAccessToken(savedUser);
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(savedUser);

        UserSummaryResponse userSummary = userMapper.toSummaryResponse(savedUser);

        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken.getToken())
            .tokenType("Bearer")
            .expiresIn(jwtTokenProvider.getAccessTokenExpiration())
            .user(userSummary)
            .build();
    }

    @Override
    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new UnauthorizedException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new UnauthorizedException("Invalid email or password");
        }

        if (!user.isEnabled()) {
            throw new UnauthorizedException("Account is disabled");
        }

        String accessToken = jwtTokenProvider.generateAccessToken(user);
        RefreshToken refreshToken = refreshTokenService.createRefreshToken(user);

        UserSummaryResponse userSummary = userMapper.toSummaryResponse(user);

        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken.getToken())
            .tokenType("Bearer")
            .expiresIn(jwtTokenProvider.getAccessTokenExpiration())
            .user(userSummary)
            .build();
    }

    @Override
    @Transactional
    public AuthResponse refreshAccessToken(RefreshTokenRequest request) {
        RefreshToken validatedToken = refreshTokenService.validateRefreshToken(request.getRefreshToken());
        refreshTokenService.revokeRefreshToken(request.getRefreshToken());

        User user = validatedToken.getUser();
        String accessToken = jwtTokenProvider.generateAccessToken(user);
        RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user);

        UserSummaryResponse userSummary = userMapper.toSummaryResponse(user);

        return AuthResponse.builder()
            .accessToken(accessToken)
            .refreshToken(newRefreshToken.getToken())
            .tokenType("Bearer")
            .expiresIn(jwtTokenProvider.getAccessTokenExpiration())
            .user(userSummary)
            .build();
    }

    @Override
    @Transactional
    public void logout(String refreshToken) {
        refreshTokenService.revokeRefreshToken(refreshToken);
    }

    @Override
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        var userOptional = userRepository.findByEmail(request.getEmail());

        if (userOptional.isEmpty()) {
            log.info("Password reset requested for non-existent email: {}", request.getEmail());
            return;
        }

        User user = userOptional.get();

        String token = UUID.randomUUID().toString();
        PasswordResetToken resetToken = PasswordResetToken.builder()
            .user(user)
            .token(token)
            .expiresAt(LocalDateTime.now().plusHours(PASSWORD_RESET_TOKEN_EXPIRATION_HOURS))
            .used(false)
            .build();

        passwordResetTokenRepository.save(resetToken);

        log.info("Password reset token generated for user: {}. Token: {}",
            user.getEmail(), token);
    }

    @Override
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository.findByToken(request.getToken())
            .orElseThrow(() -> new BadRequestException("Invalid or expired reset token"));

        if (resetToken.isUsed()) {
            throw new BadRequestException("Reset token has already been used");
        }

        if (resetToken.getExpiresAt().isBefore(LocalDateTime.now())) {
            throw new BadRequestException("Reset token has expired");
        }

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Passwords do not match");
        }

        User user = resetToken.getUser();
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        resetToken.setUsed(true);
        passwordResetTokenRepository.save(resetToken);

        refreshTokenService.revokeExistingTokens(user.getId());

        log.info("Password reset successfully for user: {}", user.getEmail());
    }
}
