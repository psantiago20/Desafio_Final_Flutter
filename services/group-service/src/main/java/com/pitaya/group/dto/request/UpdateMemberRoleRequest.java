package com.pitaya.group.dto.request;

import com.pitaya.group.enums.MemberRole;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateMemberRoleRequest {

    @NotNull(message = "Role is required")
    private MemberRole role;
}
