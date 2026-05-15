package com.pitaya.library.dto.response;

import com.pitaya.library.enums.MaterialType;
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
public class MaterialSummaryResponse {

    private UUID id;
    private String title;
    private String description;
    private MaterialType type;
    private UUID uploaderId;
    private String uploaderDisplayName;
    private UUID groupId;
    private List<String> tags;
    private int downloadCount;
    private boolean isPublic;
    private LocalDateTime createdAt;
}
