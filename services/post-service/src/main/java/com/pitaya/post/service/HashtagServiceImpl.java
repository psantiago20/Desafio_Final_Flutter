package com.pitaya.post.service;

import com.pitaya.post.dto.response.HashtagResponse;
import com.pitaya.post.entity.Hashtag;
import com.pitaya.post.mapper.HashtagMapper;
import com.pitaya.post.repository.HashtagRepository;
import com.pitaya.post.repository.PostHashtagRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@Transactional
public class HashtagServiceImpl implements HashtagService {

    private static final Logger log = LoggerFactory.getLogger(HashtagServiceImpl.class);
    private static final Pattern HASHTAG_PATTERN = Pattern.compile("#(\\w+)");
    private static final String TRENDING_CACHE_KEY = "trending:hashtags";

    private final HashtagRepository hashtagRepository;
    private final PostHashtagRepository postHashtagRepository;
    private final HashtagMapper hashtagMapper;
    private final RedisTemplate<String, Object> redisTemplate;

    public HashtagServiceImpl(HashtagRepository hashtagRepository,
                               PostHashtagRepository postHashtagRepository,
                               HashtagMapper hashtagMapper,
                               RedisTemplate<String, Object> redisTemplate) {
        this.hashtagRepository = hashtagRepository;
        this.postHashtagRepository = postHashtagRepository;
        this.hashtagMapper = hashtagMapper;
        this.redisTemplate = redisTemplate;
    }

    @Override
    public List<String> extractHashtags(String content) {
        if (content == null || content.isBlank()) return List.of();
        Matcher matcher = HASHTAG_PATTERN.matcher(content);
        List<String> tags = new ArrayList<>();
        while (matcher.find()) {
            tags.add(matcher.group(1).toLowerCase());
        }
        return tags;
    }

    @Override
    public Hashtag getOrCreateHashtag(String name) {
        String normalized = name.toLowerCase().trim();
        return hashtagRepository.findByName(normalized)
            .orElseGet(() -> {
                Hashtag hashtag = Hashtag.builder()
                    .name(normalized)
                    .usageCount(0)
                    .build();
                hashtag = hashtagRepository.save(hashtag);
                log.info("Created new hashtag: {}", normalized);
                return hashtag;
            });
    }

    @Override
    public Hashtag getHashtagById(UUID id) {
        return hashtagRepository.findById(id).orElse(null);
    }

    @Override
    public void incrementUsage(UUID hashtagId) {
        hashtagRepository.findById(hashtagId).ifPresent(hashtag -> {
            hashtag.setUsageCount(hashtag.getUsageCount() + 1);
            hashtagRepository.save(hashtag);
        });
    }

    @Override
    @Transactional(readOnly = true)
    @Cacheable(value = "trending", key = "'top_' + #limit", unless = "#result.isEmpty()")
    public List<HashtagResponse> getTrending(int limit) {
        List<Hashtag> allHashtags = hashtagRepository.findTopNByOrderByUsageCountDesc();
        return allHashtags.stream()
            .limit(limit)
            .map(hashtagMapper::toResponse)
            .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> getHashtagNamesForPost(UUID postId) {
        return postHashtagRepository.findByPostId(postId).stream()
            .map(ph -> hashtagRepository.findById(ph.getHashtagId()).orElse(null))
            .filter(h -> h != null)
            .map(Hashtag::getName)
            .collect(Collectors.toList());
    }

    @Override
    @CacheEvict(value = "trending", allEntries = true)
    public void updateTrending() {
        List<Hashtag> topHashtags = hashtagRepository.findTopNByOrderByUsageCountDesc();
        List<HashtagResponse> responses = topHashtags.stream()
            .limit(20)
            .map(hashtagMapper::toResponse)
            .collect(Collectors.toList());

        redisTemplate.opsForValue().set(
            TRENDING_CACHE_KEY, responses, 1, TimeUnit.HOURS);
        log.info("Trending hashtags updated");
    }
}
