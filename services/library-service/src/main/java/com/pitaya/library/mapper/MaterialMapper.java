package com.pitaya.library.mapper;

import com.pitaya.library.dto.request.CreateMaterialRequest;
import com.pitaya.library.dto.response.MaterialResponse;
import com.pitaya.library.dto.response.MaterialSummaryResponse;
import com.pitaya.library.entity.Material;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface MaterialMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "uploaderId", ignore = true)
    @Mapping(target = "fileSize", ignore = true)
    @Mapping(target = "fileType", ignore = true)
    @Mapping(target = "downloadCount", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Material toEntity(CreateMaterialRequest request);

    @Mapping(target = "uploaderDisplayName", ignore = true)
    @Mapping(target = "uploaderUsername", ignore = true)
    @Mapping(target = "uploaderAvatar", ignore = true)
    MaterialResponse toResponse(Material material);

    @Mapping(target = "uploaderDisplayName", ignore = true)
    MaterialSummaryResponse toSummaryResponse(Material material);
}
