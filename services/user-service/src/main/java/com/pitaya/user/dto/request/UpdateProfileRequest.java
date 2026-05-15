package com.pitaya.user.dto.request;

import com.pitaya.user.validation.ValidLattesUrl;
import com.pitaya.user.validation.ValidOrcid;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateProfileRequest {

    @Size(max = 500, message = "Avatar URL must be at most 500 characters")
    private String avatar;

    @Size(max = 500, message = "Banner URL must be at most 500 characters")
    private String banner;

    @Size(max = 5000, message = "Bio must be at most 5000 characters")
    private String bio;

    @Size(max = 255, message = "Location must be at most 255 characters")
    private String location;

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
