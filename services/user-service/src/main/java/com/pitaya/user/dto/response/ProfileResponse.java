package com.pitaya.user.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProfileResponse {

    private UUID id;
    private UUID userId;
    private String avatar;
    private String banner;
    private String bio;
    private String location;
    private String institution;
    private String course;
    private String semester;
    private String researchLine;
    private String lattesUrl;
    private String orcid;
    private String githubUrl;
    private String linkedinUrl;
    private boolean profileComplete;
    private long followerCount;
    private long followingCount;
    private long postCount;
    private boolean isFollowing;
    private List<InterestResponse> interests;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
