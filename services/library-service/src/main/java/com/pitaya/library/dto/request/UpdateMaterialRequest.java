package com.pitaya.library.dto.request;

import com.pitaya.library.enums.MaterialType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdateMaterialRequest {

    private String title;

    private String description;

    private MaterialType type;

    private String url;

    private Long fileSize;

    private String fileType;

    private List<String> tags;

    private Boolean isPublic;
}
