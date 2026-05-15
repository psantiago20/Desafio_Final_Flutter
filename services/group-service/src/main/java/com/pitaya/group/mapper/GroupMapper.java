package com.pitaya.group.mapper;

import com.pitaya.group.dto.request.CreateGroupRequest;
import com.pitaya.group.dto.response.GroupResponse;
import com.pitaya.group.dto.response.GroupSummaryResponse;
import com.pitaya.group.entity.Group;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface GroupMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "ownerId", ignore = true)
    @Mapping(target = "memberCount", constant = "1")
    @Mapping(target = "bannerUrl", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Group toEntity(CreateGroupRequest request);

    @Mapping(target = "ownerDisplayName", ignore = true)
    @Mapping(target = "ownerUsername", ignore = true)
    @Mapping(target = "ownerAvatar", ignore = true)
    @Mapping(target = "isMember", ignore = true)
    @Mapping(target = "membershipRole", ignore = true)
    GroupResponse toResponse(Group group);

    @Mapping(target = "ownerDisplayName", ignore = true)
    GroupSummaryResponse toSummaryResponse(Group group);
}
