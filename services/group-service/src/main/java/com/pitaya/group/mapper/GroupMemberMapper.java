package com.pitaya.group.mapper;

import com.pitaya.group.dto.response.MemberResponse;
import com.pitaya.group.entity.GroupMember;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface GroupMemberMapper {

    @Mapping(target = "displayName", ignore = true)
    @Mapping(target = "username", ignore = true)
    @Mapping(target = "avatar", ignore = true)
    MemberResponse toMemberResponse(GroupMember groupMember);
}
