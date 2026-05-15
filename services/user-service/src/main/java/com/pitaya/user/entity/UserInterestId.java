package com.pitaya.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInterestId implements Serializable {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "interest_id", nullable = false)
    private UUID interestId;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        UserInterestId that = (UserInterestId) o;
        return Objects.equals(userId, that.userId) &&
               Objects.equals(interestId, that.interestId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, interestId);
    }
}
