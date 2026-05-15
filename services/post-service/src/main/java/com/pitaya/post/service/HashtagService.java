package com.pitaya.post.service;

import com.pitaya.post.dto.response.HashtagResponse;
import com.pitaya.post.entity.Hashtag;

import java.util.List;
import java.util.UUID;

public interface HashtagService {

    List<String> extractHashtags(String content);

    Hashtag getOrCreateHashtag(String name);

    Hashtag getHashtagById(UUID id);

    void incrementUsage(UUID hashtagId);

    List<HashtagResponse> getTrending(int limit);

    void updateTrending();

    List<String> getHashtagNamesForPost(UUID postId);
}
