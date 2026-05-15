package com.pitaya.notification.mapper;

import com.pitaya.notification.dto.response.NotificationResponse;
import com.pitaya.notification.entity.Notification;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface NotificationMapper {

    NotificationResponse toResponse(Notification notification);
}
