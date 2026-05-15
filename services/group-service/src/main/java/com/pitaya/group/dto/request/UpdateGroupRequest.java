package com.pitaya.group.dto.request;

import com.pitaya.group.enums.GroupVisibility;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateGroupRequest {

    private String name;

    private String description;

    private String bannerUrl;

    private String category;

    private GroupVisibility visibility;

    private Boolean isActive;
}
