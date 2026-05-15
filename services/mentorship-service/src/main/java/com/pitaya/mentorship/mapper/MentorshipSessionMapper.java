package com.pitaya.mentorship.mapper;

import com.pitaya.mentorship.dto.request.CreateSessionRequest;
import com.pitaya.mentorship.dto.response.SessionResponse;
import com.pitaya.mentorship.entity.MentorshipSession;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface MentorshipSessionMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "mentorshipId", ignore = true)
    @Mapping(target = "status", ignore = true)
    @Mapping(target = "mentorNotes", ignore = true)
    @Mapping(target = "menteeFeedback", ignore = true)
    @Mapping(target = "rating", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    MentorshipSession toEntity(CreateSessionRequest request);

    SessionResponse toResponse(MentorshipSession session);
}
