package com.pitaya.shared.event.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MentorshipScheduledEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String mentorshipId;
    private String mentorId;
    private String menteeId;
    private long startTime;
    private long endTime;
    private String topic;
    private String status;
}
