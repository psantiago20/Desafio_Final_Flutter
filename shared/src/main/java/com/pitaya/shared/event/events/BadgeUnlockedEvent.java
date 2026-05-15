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
public class BadgeUnlockedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String badgeId;
    private String userId;
    private String badgeName;
    private String badgeDescription;
    private String badgeIconUrl;
    private String category;
}
