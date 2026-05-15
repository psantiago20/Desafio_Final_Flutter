package com.pitaya.post.service;

import com.pitaya.post.client.UserServiceClient;
import com.pitaya.post.client.dto.UserProfileResponse;
import com.pitaya.post.dto.request.CreateCommentRequest;
import com.pitaya.post.dto.response.CommentResponse;
import com.pitaya.post.entity.Comment;
import com.pitaya.post.entity.Post;
import com.pitaya.post.event.producer.PostEventProducer;
import com.pitaya.post.mapper.CommentMapper;
import com.pitaya.post.repository.CommentRepository;
import com.pitaya.post.repository.PostRepository;
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

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Transactional
public class CommentServiceImpl implements CommentService {

    private static final Logger log = LoggerFactory.getLogger(CommentServiceImpl.class);

    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final PostEventProducer eventProducer;
    private final CommentMapper commentMapper;
    private final UserServiceClient userServiceClient;

    public CommentServiceImpl(CommentRepository commentRepository,
                               PostRepository postRepository,
                               PostEventProducer eventProducer,
                               CommentMapper commentMapper,
                               UserServiceClient userServiceClient) {
        this.commentRepository = commentRepository;
        this.postRepository = postRepository;
        this.eventProducer = eventProducer;
        this.commentMapper = commentMapper;
        this.userServiceClient = userServiceClient;
    }

    @Override
    public CommentResponse addComment(UUID postId, UUID userId, CreateCommentRequest request) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (request.getParentCommentId() != null) {
            commentRepository.findById(request.getParentCommentId())
                .orElseThrow(() -> new ResourceNotFoundException("Comment", "id", request.getParentCommentId()));
        }

        Comment comment = Comment.builder()
            .postId(postId)
            .userId(userId)
            .parentId(request.getParentCommentId())
            .content(request.getContent())
            .build();

        comment = commentRepository.save(comment);

        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);

        eventProducer.publishCommentAddedEvent(
            comment.getId(), postId, userId,
            request.getContent(), request.getParentCommentId());

        log.info("Comment added: {} on post: {} by user: {}", comment.getId(), postId, userId);
        return enrichCommentResponse(comment);
    }

    @Override
    @Transactional(readOnly = true)
    public PagedResponse<CommentResponse> getComments(UUID postId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Comment> comments = commentRepository.findByPostIdOrderByCreatedAtAsc(postId, pageable);

        List<CommentResponse> content = comments.getContent().stream()
            .map(this::enrichCommentResponse)
            .collect(Collectors.toList());

        return PagedResponse.<CommentResponse>builder()
            .content(content)
            .page(page)
            .size(size)
            .totalElements(comments.getTotalElements())
            .totalPages(comments.getTotalPages())
            .last(comments.isLast())
            .build();
    }

    @Override
    public void deleteComment(UUID commentId, UUID userId) {
        Comment comment = commentRepository.findById(commentId)
            .orElseThrow(() -> new ResourceNotFoundException("Comment", "id", commentId));

        if (!comment.getUserId().equals(userId)) {
            Optional<Post> post = postRepository.findById(comment.getPostId());
            if (post.isEmpty() || !post.get().getUserId().equals(userId)) {
                throw new ForbiddenException("You can only delete your own comments");
            }
        }

        Post post = postRepository.findById(comment.getPostId())
            .orElse(null);
        if (post != null) {
            post.setCommentCount(Math.max(0, post.getCommentCount() - 1));
            postRepository.save(post);
        }

        commentRepository.delete(comment);
        log.info("Comment deleted: {} by user: {}", commentId, userId);
    }

    private CommentResponse enrichCommentResponse(Comment comment) {
        CommentResponse response = commentMapper.toResponse(comment);
        if (response == null) {
            response = new CommentResponse();
        }
        response.setId(comment.getId());
        response.setPostId(comment.getPostId());
        response.setUserId(comment.getUserId());
        response.setParentId(comment.getParentId());
        response.setContent(comment.getContent());
        response.setCreatedAt(comment.getCreatedAt());
        response.setUpdatedAt(comment.getUpdatedAt());

        enrichAuthorInfo(response, comment.getUserId());

        return response;
    }

    private void enrichAuthorInfo(CommentResponse response, UUID authorId) {
        try {
            var apiResponse = userServiceClient.getUserProfile(authorId);
            if (apiResponse != null && apiResponse.getData() != null) {
                UserProfileResponse profile = apiResponse.getData();
                response.setAuthorAvatar(profile.getAvatar());
            }
        } catch (Exception e) {
            log.warn("Failed to fetch author info for user: {}", authorId, e);
        }
    }
}
