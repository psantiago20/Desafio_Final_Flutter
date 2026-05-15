package com.pitaya.gamification.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class XpTransactionResponse {

    private int amount;
    private String reason;
    private LocalDateTime createdAt;
}
