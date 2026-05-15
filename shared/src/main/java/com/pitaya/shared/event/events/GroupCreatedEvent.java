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
public class GroupCreatedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String groupId;
    private String name;
    private String description;
    private String ownerId;
    private String category;
    private boolean isPrivate;
}
