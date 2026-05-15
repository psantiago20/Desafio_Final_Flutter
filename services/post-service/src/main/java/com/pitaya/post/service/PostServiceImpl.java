package com.pitaya.post.service;

import com.pitaya.post.client.UserServiceClient;
import com.pitaya.post.client.dto.UserProfileResponse;
import com.pitaya.post.dto.request.CreatePostRequest;
import com.pitaya.post.dto.request.UpdatePostRequest;
import com.pitaya.post.dto.response.PostResponse;
import com.pitaya.post.entity.Hashtag;
import com.pitaya.post.entity.Post;
import com.pitaya.post.entity.PostHashtag;
import com.pitaya.post.entity.PostHashtagId;
import com.pitaya.post.event.producer.PostEventProducer;
import com.pitaya.post.mapper.PostMapper;
import com.pitaya.post.repository.LikeRepository;
import com.pitaya.post.repository.PostHashtagRepository;
import com.pitaya.post.repository.PostRepository;
import com.pitaya.post.repository.RepostRepository;
import com.pitaya.shared.dto.PagedResponse;
import com.pitaya.shared.exception.ForbiddenException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@Transactional
public class PostServiceImpl implements PostService {

    private static final Logger log = LoggerFactory.getLogger(PostServiceImpl.class);
    private static final Pattern HASHTAG_PATTERN = Pattern.compile("#(\\w+)");

    private final PostRepository postRepository;
    private final PostHashtagRepository postHashtagRepository;
    private final LikeRepository likeRepository;
    private final RepostRepository repostRepository;
    private final HashtagService hashtagService;
    private final PostEventProducer eventProducer;
    private final PostMapper postMapper;
    private final UserServiceClient userServiceClient;

    public PostServiceImpl(PostRepository postRepository,
                            PostHashtagRepository postHashtagRepository,
                            LikeRepository likeRepository,
                            RepostRepository repostRepository,
                            HashtagService hashtagService,
                            PostEventProducer eventProducer,
                            PostMapper postMapper,
                            UserServiceClient userServiceClient) {
        this.postRepository = postRepository;
        this.postHashtagRepository = postHashtagRepository;
        this.likeRepository = likeRepository;
        this.repostRepository = repostRepository;
        this.hashtagService = hashtagService;
        this.eventProducer = eventProducer;
        this.postMapper = postMapper;
        this.userServiceClient = userServiceClient;
    }

    @Override
    public PostResponse createPost(UUID userId, CreatePostRequest request) {
        Post post = postMapper.toEntity(request);
        post.setUserId(userId);
        post = postRepository.save(post);

        List<String> hashtags = extractHashtags(request.getContent());
        if (!hashtags.isEmpty()) {
            for (String tag : hashtags) {
                Hashtag hashtag = hashtagService.getOrCreateHashtag(tag);
                PostHashtagId id = new PostHashtagId(post.getId(), hashtag.getId());
                PostHashtag ph = PostHashtag.builder().id(id).build();
                postHashtagRepository.save(ph);
                hashtagService.incrementUsage(hashtag.getId());
            }
        }

        eventProducer.publishPostCreatedEvent(
            post.getId(), userId, post.getContent(),
            post.getImageUrl() != null ? List.of(post.getImageUrl()) : Collections.emptyList(),
            hashtags,
            post.getVisibility().name()
        );

        log.info("Post created: {} by user: {}", post.getId(), userId);
        return enrichPostResponse(post, userId, hashtags);
    }

    @Override
    @Transactional(readOnly = true)
    public PostResponse getPost(UUID postId, UUID currentUserId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        checkAccessibility(post, currentUserId);

        List<String> hashtags = getHashtagsForPost(postId);
        return enrichPostResponse(post, currentUserId, hashtags);
    }

    @Override
    @Transactional(readOnly = true)
    public PostResponse getPostByIdForInternal(UUID postId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));
        List<String> hashtags = getHashtagsForPost(postId);
        return enrichPostResponse(post, null, hashtags);
    }

    @Override
    public PostResponse updatePost(UUID postId, UUID userId, UpdatePostRequest request) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (!post.getUserId().equals(userId)) {
            throw new ForbiddenException("You can only update your own posts");
        }

        if (request.getContent() != null) {
            post.setContent(request.getContent());
        }
        if (request.getVisibility() != null) {
            post.setVisibility(request.getVisibility());
        }

        post = postRepository.save(post);
        log.info("Post updated: {}", postId);

        List<String> hashtags = getHashtagsForPost(postId);
        return enrichPostResponse(post, userId, hashtags);
    }

    @Override
    public void deletePost(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (!post.getUserId().equals(userId)) {
            throw new ForbiddenException("You can only delete your own posts");
        }

        postHashtagRepository.deleteByPostId(postId);
        likeRepository.deleteByPostId(postId);
        repostRepository.deleteByOriginalPostId(postId);
        postRepository.delete(post);

        log.info("Post deleted: {} by user: {}", postId, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<PostResponse> getUserPosts(UUID userId, UUID currentUserId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<UUID> followingIds = currentUserId != null ?
            getFollowingIds(currentUserId) : Collections.emptyList();

        Page<Post> posts;
        if (currentUserId != null && currentUserId.equals(userId)) {
            posts = postRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        } else {
            posts = postRepository.findUserPostsWithVisibility(
                userId, currentUserId, followingIds, pageable);
        }

        List<PostResponse> content = posts.getContent().stream()
            .map(post -> {
                List<String> hashtags = getHashtagsForPost(post.getId());
                return enrichPostResponse(post, currentUserId, hashtags);
            })
            .collect(Collectors.toList());

        return buildPagedResponse(content, posts, page, size);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<PostResponse> getByHashtag(String hashtag, UUID currentUserId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<UUID> followingIds = currentUserId != null ?
            getFollowingIds(currentUserId) : Collections.emptyList();

        Page<Post> posts = postRepository.findByHashtagWithAccess(
            hashtag, currentUserId, followingIds, pageable);

        List<PostResponse> content = posts.getContent().stream()
            .map(post -> {
                List<String> tags = getHashtagsForPost(post.getId());
                return enrichPostResponse(post, currentUserId, tags);
            })
            .collect(Collectors.toList());

        return buildPagedResponse(content, posts, page, size);
    }

    @Override
    public void togglePin(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (!post.getUserId().equals(userId)) {
            throw new ForbiddenException("You can only pin your own posts");
        }

        post.setPinned(!post.isPinned());
        postRepository.save(post);
        log.info("Post {} pin toggled to {} for user: {}", postId, post.isPinned(), userId);
    }

    void checkAccessibility(Post post, UUID currentUserId) {
        if (post.getVisibility() == null) return;

        switch (post.getVisibility()) {
            case PUBLIC -> {}
            case FOLLOWERS_ONLY -> {
                if (currentUserId == null || (!currentUserId.equals(post.getUserId()) &&
                    !isFollowing(currentUserId, post.getUserId()))) {
                    throw new ForbiddenException("This post is only visible to followers");
                }
            }
            case PRIVATE -> {
                if (currentUserId == null || !currentUserId.equals(post.getUserId())) {
                    throw new ForbiddenException("This post is private");
                }
            }
        }
    }

    private boolean isFollowing(UUID followerId, UUID followingId) {
        try {
            var response = userServiceClient.getFollowing(followerId, 0, 1);
            return response != null && response.getData() != null &&
                response.getData().getContent().stream()
                    .anyMatch(u -> u.getId().equals(followingId));
        } catch (Exception e) {
            log.warn("Failed to check follow status: {}", e.getMessage());
            return false;
        }
    }

    List<String> extractHashtags(String content) {
        if (content == null || content.isBlank()) return Collections.emptyList();
        Matcher matcher = HASHTAG_PATTERN.matcher(content);
        List<String> tags = new ArrayList<>();
        while (matcher.find()) {
            tags.add(matcher.group(1).toLowerCase());
        }
        return tags;
    }

    private List<String> getHashtagsForPost(UUID postId) {
        List<PostHashtag> postHashtags = postHashtagRepository.findByPostId(postId);
        return postHashtags.stream()
            .map(ph -> hashtagService.getHashtagById(ph.getHashtagId()))
            .filter(h -> h != null)
            .map(h -> h.getName())
            .collect(Collectors.toList());
    }

    private PostResponse enrichPostResponse(Post post, UUID currentUserId, List<String> hashtags) {
        PostResponse response = postMapper.toResponse(post);
        if (response == null) {
            response = new PostResponse();
        }
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

        if (hashtags != null) {
            response.setHashtags(hashtags);
        } else {
            response.setHashtags(Collections.emptyList());
        }

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
                UserProfileResponse profile = apiResponse.getData();
                response.setAuthorAvatar(profile.getAvatar());
                response.setAuthorBio(profile.getBio());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch author info for user: {}", authorId, e);
        }
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

    private <T> PagedResponse<T> buildPagedResponse(List<T> content, Page<?> page, int pageNo, int size) {
        return PagedResponse.<T>builder()
            .content(content)
            .page(pageNo)
            .size(size)
            .totalElements(page.getTotalElements())
            .totalPages(page.getTotalPages())
            .last(page.isLast())
            .build();
    }
}
