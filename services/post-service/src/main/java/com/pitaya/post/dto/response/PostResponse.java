package com.pitaya.post.dto.response;

import com.pitaya.post.entity.Visibility;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostResponse {

    private UUID id;
    private UUID userId;
    private String content;
    private String imageUrl;
    private Visibility visibility;
    private boolean isPinned;
    private int likeCount;
    private int commentCount;
    private int repostCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    private String authorDisplayName;
    private String authorUsername;
    private String authorAvatar;
    private String authorBio;

    private boolean isLiked;
    private boolean isReposted;

    private List<String> hashtags;
}
