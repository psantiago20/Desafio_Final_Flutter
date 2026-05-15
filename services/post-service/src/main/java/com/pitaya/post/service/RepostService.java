package com.pitaya.post.service;

import java.util.UUID;

public interface RepostService {

    void repost(UUID postId, UUID userId);

    void removeRepost(UUID postId, UUID userId);
}
