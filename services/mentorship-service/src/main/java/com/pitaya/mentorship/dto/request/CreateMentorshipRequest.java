package com.pitaya.mentorship.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateMentorshipRequest {

    @NotNull(message = "Mentor ID is required")
    private UUID mentorId;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    private Integer maxSessions;
}
