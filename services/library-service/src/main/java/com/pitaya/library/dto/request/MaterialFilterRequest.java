package com.pitaya.library.dto.request;

import com.pitaya.library.enums.MaterialType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MaterialFilterRequest {

    private MaterialType type;

    private UUID groupId;

    private String search;

    private List<String> tags;

    private Boolean isPublic;
}
