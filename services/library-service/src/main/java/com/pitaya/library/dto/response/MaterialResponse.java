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
public class MaterialResponse {

    private UUID id;
    private String title;
    private String description;
    private MaterialType type;
    private String url;
    private Long fileSize;
    private String fileType;
    private UUID uploaderId;
    private String uploaderDisplayName;
    private String uploaderUsername;
    private String uploaderAvatar;
    private UUID groupId;
    private List<String> tags;
    private int downloadCount;
    private boolean isPublic;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
