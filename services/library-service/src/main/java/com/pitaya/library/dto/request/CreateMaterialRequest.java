package com.pitaya.library.dto.request;

import com.pitaya.library.enums.MaterialType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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
public class CreateMaterialRequest {

    @NotBlank(message = "Title is required")
    @Size(min = 1, max = 500, message = "Title must be between 1 and 500 characters")
    private String title;

    @Size(max = 5000, message = "Description must not exceed 5000 characters")
    private String description;

    private MaterialType type;

    @Size(max = 2048, message = "URL must not exceed 2048 characters")
    private String url;

    private UUID groupId;

    private List<String> tags;

    private Boolean isPublic;
}
