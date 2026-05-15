package com.pitaya.user.dto.request;

import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateInterestsRequest {

    @NotEmpty(message = "Interests list cannot be empty")
    private List<String> interests;
}
