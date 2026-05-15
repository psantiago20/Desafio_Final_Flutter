package com.pitaya.gamification.mapper;

import com.pitaya.gamification.dto.response.BadgeResponse;
import com.pitaya.gamification.entity.Badge;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface BadgeMapper {

    BadgeResponse toResponse(Badge badge);
}
