package com.pitaya.mentorship.dto.response;

import com.pitaya.mentorship.entity.SessionStatus;
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
public class SessionResponse {

    private UUID id;
    private UUID mentorshipId;
    private String title;
    private String description;
    private LocalDateTime scheduledAt;
    private Integer durationMinutes;
    private SessionStatus status;
    private String meetingLink;
    private String mentorNotes;
    private String menteeFeedback;
    private Integer rating;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
