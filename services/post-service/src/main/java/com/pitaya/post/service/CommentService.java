package com.pitaya.post.service;

import com.pitaya.post.dto.request.CreateCommentRequest;
import com.pitaya.post.dto.response.CommentResponse;
import com.pitaya.shared.dto.PagedResponse;

import java.util.UUID;

public interface CommentService {

    CommentResponse addComment(UUID postId, UUID userId, CreateCommentRequest request);

    PagedResponse<CommentResponse> getComments(UUID postId, int page, int size);

    void deleteComment(UUID commentId, UUID userId);
}
