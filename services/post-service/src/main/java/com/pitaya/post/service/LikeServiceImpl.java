package com.pitaya.post.service;

import com.pitaya.post.entity.Like;
import com.pitaya.post.entity.Post;
import com.pitaya.post.event.producer.PostEventProducer;
import com.pitaya.post.repository.LikeRepository;
import com.pitaya.post.repository.PostRepository;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class LikeServiceImpl implements LikeService {

    private static final Logger log = LoggerFactory.getLogger(LikeServiceImpl.class);

    private final LikeRepository likeRepository;
    private final PostRepository postRepository;
    private final PostEventProducer eventProducer;

    public LikeServiceImpl(LikeRepository likeRepository,
                            PostRepository postRepository,
                            PostEventProducer eventProducer) {
        this.likeRepository = likeRepository;
        this.postRepository = postRepository;
        this.eventProducer = eventProducer;
    }

    @Override
    public void likePost(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (likeRepository.existsByUserIdAndPostId(userId, postId)) {
            throw new BadRequestException("You already liked this post");
        }

        Like like = Like.builder()
            .userId(userId)
            .postId(postId)
            .build();
        likeRepository.save(like);

        post.setLikeCount(post.getLikeCount() + 1);
        postRepository.save(post);

        eventProducer.publishPostLikedEvent(postId, userId, post.getUserId(), true);
        log.info("User {} liked post {}", userId, postId);
    }

    @Override
    public void unlikePost(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (!likeRepository.existsByUserIdAndPostId(userId, postId)) {
            throw new BadRequestException("You have not liked this post");
        }

        likeRepository.deleteByUserIdAndPostId(userId, postId);

        post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
        postRepository.save(post);

        eventProducer.publishPostLikedEvent(postId, userId, post.getUserId(), false);
        log.info("User {} unliked post {}", userId, postId);
    }
}
