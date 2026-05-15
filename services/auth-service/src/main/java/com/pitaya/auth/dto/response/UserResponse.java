package com.pitaya.auth.dto.response;

import com.pitaya.auth.entity.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {

    private UUID id;
    private String email;
    private String fullName;
    private String username;
    private Role role;
    private LocalDate birthDate;
    private boolean enabled;
    private boolean emailVerified;
    private String avatar;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
