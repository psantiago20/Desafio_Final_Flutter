package com.pitaya.user.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "user_interests")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInterest {

    @EmbeddedId
    private UserInterestId id;

    public UUID getUserId() {
        return id.getUserId();
    }

    public UUID getInterestId() {
        return id.getInterestId();
    }
}
