package com.pitaya.post.controller;

import com.pitaya.post.dto.request.CreateCommentRequest;
import com.pitaya.post.dto.request.CreatePostRequest;
import com.pitaya.post.dto.request.RepostRequest;
import com.pitaya.post.dto.request.UpdatePostRequest;
import com.pitaya.post.dto.response.CommentResponse;
import com.pitaya.post.dto.response.HashtagResponse;
import com.pitaya.post.dto.response.PostResponse;
import com.pitaya.post.service.CommentService;
import com.pitaya.post.service.HashtagService;
import com.pitaya.post.service.LikeService;
import com.pitaya.post.service.PostService;
import com.pitaya.post.service.RepostService;
import com.pitaya.post.service.TimelineService;
import com.pitaya.shared.dto.ApiResponse;
import com.pitaya.shared.dto.PagedResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/posts")
public class PostController {

    private final PostService postService;
    private final CommentService commentService;
    private final LikeService likeService;
    private final RepostService repostService;
    private final HashtagService hashtagService;
    private final TimelineService timelineService;

    public PostController(PostService postService,
                           CommentService commentService,
                           LikeService likeService,
                           RepostService repostService,
                           HashtagService hashtagService,
                           TimelineService timelineService) {
        this.postService = postService;
        this.commentService = commentService;
        this.likeService = likeService;
        this.repostService = repostService;
        this.hashtagService = hashtagService;
        this.timelineService = timelineService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PostResponse>> createPost(
            @Valid @RequestBody CreatePostRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        PostResponse post = postService.createPost(userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Post created successfully", post));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PostResponse>> getPost(
            @PathVariable UUID id,
            Principal principal) {
        UUID currentUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        PostResponse post = postService.getPost(id, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(post));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<PostResponse>> updatePost(
            @PathVariable UUID id,
            @Valid @RequestBody UpdatePostRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        PostResponse post = postService.updatePost(id, userId, request);
        return ResponseEntity.ok(ApiResponse.success("Post updated successfully", post));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePost(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        postService.deletePost(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Post deleted successfully", null));
    }

    @GetMapping("/timeline")
    public ResponseEntity<ApiResponse<PagedResponse<PostResponse>>> getTimeline(
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getName());
        PagedResponse<PostResponse> timeline = timelineService.getTimeline(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success(timeline));
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<ApiResponse<PagedResponse<PostResponse>>> getUserPosts(
            @PathVariable UUID userId,
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID currentUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        PagedResponse<PostResponse> posts = postService.getUserPosts(userId, currentUserId, page, size);
        return ResponseEntity.ok(ApiResponse.success(posts));
    }

    @GetMapping("/explore")
    public ResponseEntity<ApiResponse<PagedResponse<PostResponse>>> getExplorePosts(
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID userId = UUID.fromString(principal.getName());
        PagedResponse<PostResponse> posts = timelineService.getExplorePosts(userId, page, size);
        return ResponseEntity.ok(ApiResponse.success(posts));
    }

    @GetMapping("/hashtag/{name}")
    public ResponseEntity<ApiResponse<PagedResponse<PostResponse>>> getPostsByHashtag(
            @PathVariable String name,
            Principal principal,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        UUID currentUserId = principal != null ? UUID.fromString(principal.getName()) : null;
        PagedResponse<PostResponse> posts = postService.getByHashtag(name, currentUserId, page, size);
        return ResponseEntity.ok(ApiResponse.success(posts));
    }

    @GetMapping("/trending")
    public ResponseEntity<ApiResponse<List<HashtagResponse>>> getTrendingHashtags(
            @RequestParam(defaultValue = "10") int limit) {
        List<HashtagResponse> trending = hashtagService.getTrending(limit);
        return ResponseEntity.ok(ApiResponse.success(trending));
    }

    @PostMapping("/{id}/pin")
    public ResponseEntity<ApiResponse<Void>> togglePin(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        postService.togglePin(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Pin toggled successfully", null));
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Void>> likePost(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        likeService.likePost(id, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Post liked successfully", null));
    }

    @DeleteMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Void>> unlikePost(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        likeService.unlikePost(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Post unliked successfully", null));
    }

    @PostMapping("/{id}/repost")
    public ResponseEntity<ApiResponse<Void>> repost(
            @PathVariable UUID id,
            @RequestBody(required = false) RepostRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        repostService.repost(id, userId);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Post reposted successfully", null));
    }

    @DeleteMapping("/{id}/repost")
    public ResponseEntity<ApiResponse<Void>> removeRepost(
            @PathVariable UUID id,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        repostService.removeRepost(id, userId);
        return ResponseEntity.ok(ApiResponse.success("Repost removed successfully", null));
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<ApiResponse<CommentResponse>> addComment(
            @PathVariable UUID id,
            @Valid @RequestBody CreateCommentRequest request,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        CommentResponse comment = commentService.addComment(id, userId, request);
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success("Comment added successfully", comment));
    }

    @GetMapping("/{id}/comments")
    public ResponseEntity<ApiResponse<PagedResponse<CommentResponse>>> getComments(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        PagedResponse<CommentResponse> comments = commentService.getComments(id, page, size);
        return ResponseEntity.ok(ApiResponse.success(comments));
    }

    @DeleteMapping("/comments/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(
            @PathVariable UUID commentId,
            Principal principal) {
        UUID userId = UUID.fromString(principal.getName());
        commentService.deleteComment(commentId, userId);
        return ResponseEntity.ok(ApiResponse.success("Comment deleted successfully", null));
    }
}
