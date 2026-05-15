package com.pitaya.post.service;

import com.pitaya.post.client.UserServiceClient;
import com.pitaya.post.dto.response.PostResponse;
import com.pitaya.post.entity.Post;
import com.pitaya.post.repository.LikeRepository;
import com.pitaya.post.repository.PostRepository;
import com.pitaya.post.repository.RepostRepository;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class TimelineService {

    private static final Logger log = LoggerFactory.getLogger(TimelineService.class);

    private final PostRepository postRepository;
    private final LikeRepository likeRepository;
    private final RepostRepository repostRepository;
    private final HashtagService hashtagService;
    private final UserServiceClient userServiceClient;

    public TimelineService(PostRepository postRepository,
                            LikeRepository likeRepository,
                            RepostRepository repostRepository,
                            HashtagService hashtagService,
                            UserServiceClient userServiceClient) {
        this.postRepository = postRepository;
        this.likeRepository = likeRepository;
        this.repostRepository = repostRepository;
        this.hashtagService = hashtagService;
        this.userServiceClient = userServiceClient;
    }

    @Cacheable(value = "timelines", key = "#userId + '_' + #page + '_' + #size",
               unless = "#result.content.isEmpty()")
    public PagedResponse<PostResponse> getTimeline(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<UUID> followingIds = getFollowingIds(userId);

        Page<Post> posts = postRepository.findAccessiblePosts(userId, followingIds, pageable);

        List<PostResponse> content = posts.getContent().stream()
            .map(post -> buildPostResponse(post, userId))
            .collect(Collectors.toList());

        return PagedResponse.<PostResponse>builder()
            .content(content)
            .page(page)
            .size(size)
            .totalElements(posts.getTotalElements())
            .totalPages(posts.getTotalPages())
            .last(posts.isLast())
            .build();
    }

    @Cacheable(value = "timelines", key = "'explore_' + #userId + '_' + #page + '_' + #size",
               unless = "#result.content.isEmpty()")
    public PagedResponse<PostResponse> getExplorePosts(UUID userId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<UUID> followingIds = getFollowingIds(userId);

        Page<Post> posts = postRepository.findExplorePosts(userId, followingIds, pageable);

        List<PostResponse> content = posts.getContent().stream()
            .map(post -> buildPostResponse(post, userId))
            .collect(Collectors.toList());

        return PagedResponse.<PostResponse>builder()
            .content(content)
            .page(page)
            .size(size)
            .totalElements(posts.getTotalElements())
            .totalPages(posts.getTotalPages())
            .last(posts.isLast())
            .build();
    }

    @CacheEvict(value = "timelines", key = "#userId + '*'")
    public void evictTimelineCache(UUID userId) {
        log.info("Evicting timeline cache for user: {}", userId);
    }

    private PostResponse buildPostResponse(Post post, UUID currentUserId) {
        PostResponse response = new PostResponse();
        response.setId(post.getId());
        response.setUserId(post.getUserId());
        response.setContent(post.getContent());
        response.setImageUrl(post.getImageUrl());
        response.setVisibility(post.getVisibility());
        response.setPinned(post.isPinned());
        response.setLikeCount(post.getLikeCount());
        response.setCommentCount(post.getCommentCount());
        response.setRepostCount(post.getRepostCount());
        response.setCreatedAt(post.getCreatedAt());
        response.setUpdatedAt(post.getUpdatedAt());

        List<String> hashtags = getHashtagsForPost(post.getId());
        response.setHashtags(hashtags);

        if (currentUserId != null) {
            response.setLiked(likeRepository.existsByUserIdAndPostId(currentUserId, post.getId()));
            response.setReposted(repostRepository.existsByUserIdAndOriginalPostId(currentUserId, post.getId()));
        }

        enrichAuthorInfo(response, post.getUserId());

        return response;
    }

    private void enrichAuthorInfo(PostResponse response, UUID authorId) {
        try {
            var apiResponse = userServiceClient.getUserProfile(authorId);
            if (apiResponse != null && apiResponse.getData() != null) {
                var profile = apiResponse.getData();
                response.setAuthorAvatar(profile.getAvatar());
                response.setAuthorBio(profile.getBio());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch author info for user: {}", authorId, e);
        }
    }

    private List<String> getHashtagsForPost(UUID postId) {
        return hashtagService.getHashtagNamesForPost(postId);
    }

    private List<UUID> getFollowingIds(UUID userId) {
        try {
            var response = userServiceClient.getFollowing(userId, 0, 1000);
            if (response != null && response.getData() != null) {
                return response.getData().getContent().stream()
                    .map(u -> u.getId())
                    .collect(Collectors.toList());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch following list for user: {}", userId, e);
        }
        return Collections.emptyList();
    }
}
