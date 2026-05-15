package com.pitaya.user.mapper;

import com.pitaya.user.dto.response.InterestResponse;
import com.pitaya.user.entity.Interest;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

import java.util.List;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface InterestMapper {

    InterestResponse toResponse(Interest interest);

    List<InterestResponse> toResponseList(List<Interest> interests);
}
