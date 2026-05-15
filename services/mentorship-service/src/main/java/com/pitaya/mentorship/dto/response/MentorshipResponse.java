package com.pitaya.mentorship.dto.response;

import com.pitaya.mentorship.entity.MentorshipStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MentorshipResponse {

    private UUID id;
    private UUID mentorId;
    private UUID menteeId;
    private String mentorDisplayName;
    private String mentorUsername;
    private String mentorAvatar;
    private String menteeDisplayName;
    private String menteeUsername;
    private String menteeAvatar;
    private String title;
    private String description;
    private MentorshipStatus status;
    private LocalDateTime startDate;
    private LocalDateTime endDate;
    private Integer maxSessions;
    private int sessionCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
