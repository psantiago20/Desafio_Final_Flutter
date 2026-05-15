package com.pitaya.mentorship.mapper;

import com.pitaya.mentorship.dto.request.CreateMentorshipRequest;
import com.pitaya.mentorship.dto.response.MentorshipResponse;
import com.pitaya.mentorship.dto.response.MentorshipSummaryResponse;
import com.pitaya.mentorship.entity.Mentorship;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface MentorshipMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "mentorId", ignore = true)
    @Mapping(target = "menteeId", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "startDate", ignore = true)
    @Mapping(target = "endDate", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Mentorship toEntity(CreateMentorshipRequest request);

    @Mapping(target = "mentorDisplayName", ignore = true)
    @Mapping(target = "mentorUsername", ignore = true)
    @Mapping(target = "mentorAvatar", ignore = true)
    @Mapping(target = "menteeDisplayName", ignore = true)
    @Mapping(target = "menteeUsername", ignore = true)
    @Mapping(target = "menteeAvatar", ignore = true)
    @Mapping(target = "sessionCount", ignore = true)
    MentorshipResponse toResponse(Mentorship mentorship);

    @Mapping(target = "mentorDisplayName", ignore = true)
    @Mapping(target = "mentorUsername", ignore = true)
    @Mapping(target = "mentorAvatar", ignore = true)
    @Mapping(target = "menteeDisplayName", ignore = true)
    @Mapping(target = "menteeUsername", ignore = true)
    @Mapping(target = "menteeAvatar", ignore = true)
    @Mapping(target = "sessionCount", ignore = true)
    MentorshipSummaryResponse toSummaryResponse(Mentorship mentorship);
}
