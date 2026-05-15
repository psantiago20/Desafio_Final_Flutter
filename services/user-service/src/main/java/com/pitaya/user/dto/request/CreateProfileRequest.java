package com.pitaya.user.dto.request;

import com.pitaya.user.validation.ValidLattesUrl;
import com.pitaya.user.validation.ValidOrcid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateProfileRequest {

    @NotBlank(message = "Institution is required")
    @Size(max = 255, message = "Institution must be at most 255 characters")
    private String institution;

    @Size(max = 255, message = "Course must be at most 255 characters")
    private String course;

    @Size(max = 50, message = "Semester must be at most 50 characters")
    private String semester;

    @Size(max = 500, message = "Research line must be at most 500 characters")
    private String researchLine;

    @ValidLattesUrl
    private String lattesUrl;

    @ValidOrcid
    private String orcid;

    @Size(max = 500, message = "GitHub URL must be at most 500 characters")
    private String githubUrl;

    @Size(max = 500, message = "LinkedIn URL must be at most 500 characters")
    private String linkedinUrl;
}
