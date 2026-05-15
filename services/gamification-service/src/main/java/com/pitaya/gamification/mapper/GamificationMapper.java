package com.pitaya.gamification.mapper;

import com.pitaya.gamification.dto.response.XpTransactionResponse;
import com.pitaya.gamification.entity.XpTransaction;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface GamificationMapper {

    XpTransactionResponse toXpTransactionResponse(XpTransaction transaction);
}
