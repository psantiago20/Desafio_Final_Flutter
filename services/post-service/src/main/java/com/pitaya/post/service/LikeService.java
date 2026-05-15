package com.pitaya.post.service;

import java.util.UUID;

public interface LikeService {

    void likePost(UUID postId, UUID userId);

    void unlikePost(UUID postId, UUID userId);
}
