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
public class ProfileUpdatedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String userId;
    private String displayName;
    private String bio;
    private String avatarUrl;
    private String location;
    private String website;
}
