package com.pitaya.user.mapper;

import com.pitaya.user.dto.request.CreateProfileRequest;
import com.pitaya.user.dto.response.InterestResponse;
import com.pitaya.user.dto.response.ProfileResponse;
import com.pitaya.user.dto.response.UserSummaryResponse;
import com.pitaya.user.entity.Interest;
import com.pitaya.user.entity.Profile;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface ProfileMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "avatar", ignore = true)
    @Mapping(target = "banner", ignore = true)
    @Mapping(target = "bio", ignore = true)
    @Mapping(target = "location", ignore = true)
    @Mapping(target = "profileComplete", constant = "true")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Profile toEntity(CreateProfileRequest request);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "userId", ignore = true)
    @Mapping(target = "avatar", ignore = true)
    @Mapping(target = "banner", ignore = true)
    @Mapping(target = "profileComplete", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    void updateEntity(CreateProfileRequest request, @MappingTarget Profile profile);

    @Mapping(target = "followerCount", ignore = true)
    @Mapping(target = "followingCount", ignore = true)
    @Mapping(target = "postCount", ignore = true)
    @Mapping(target = "isFollowing", ignore = true)
    @Mapping(target = "interests", ignore = true)
    ProfileResponse toResponse(Profile profile);

    UserSummaryResponse toSummaryResponse(Profile profile);
}
