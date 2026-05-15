package com.pitaya.post.entity;

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
@Table(name = "post_hashtags")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PostHashtag {

    @EmbeddedId
    private PostHashtagId id;

    public UUID getPostId() {
        return id.getPostId();
    }

    public UUID getHashtagId() {
        return id.getHashtagId();
    }
}
