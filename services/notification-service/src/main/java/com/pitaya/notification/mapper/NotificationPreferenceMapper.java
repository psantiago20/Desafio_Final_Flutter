package com.pitaya.notification.mapper;

import com.pitaya.notification.dto.response.NotificationPreferenceResponse;
import com.pitaya.notification.entity.NotificationPreference;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface NotificationPreferenceMapper {

    NotificationPreferenceResponse toResponse(NotificationPreference preference);
}
