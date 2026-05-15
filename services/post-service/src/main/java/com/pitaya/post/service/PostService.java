package com.pitaya.post.service;

import com.pitaya.post.dto.request.CreatePostRequest;
import com.pitaya.post.dto.request.UpdatePostRequest;
import com.pitaya.post.dto.response.PostResponse;
import com.pitaya.shared.dto.PagedResponse;

import java.util.UUID;

public interface PostService {

    PostResponse createPost(UUID userId, CreatePostRequest request);

    PostResponse getPost(UUID postId, UUID currentUserId);

    PostResponse getPostByIdForInternal(UUID postId);

    PostResponse updatePost(UUID postId, UUID userId, UpdatePostRequest request);

    void deletePost(UUID postId, UUID userId);

    PagedResponse<PostResponse> getUserPosts(UUID userId, UUID currentUserId, int page, int size);

    PagedResponse<PostResponse> getByHashtag(String hashtag, UUID currentUserId, int page, int size);

    void togglePin(UUID postId, UUID userId);
}
