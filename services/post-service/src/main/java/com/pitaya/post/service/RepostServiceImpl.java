package com.pitaya.post.service;

import com.pitaya.post.entity.Post;
import com.pitaya.post.entity.Repost;
import com.pitaya.post.repository.PostRepository;
import com.pitaya.post.repository.RepostRepository;
import com.pitaya.shared.exception.BadRequestException;
import com.pitaya.shared.exception.ResourceNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class RepostServiceImpl implements RepostService {

    private static final Logger log = LoggerFactory.getLogger(RepostServiceImpl.class);

    private final RepostRepository repostRepository;
    private final PostRepository postRepository;

    public RepostServiceImpl(RepostRepository repostRepository,
                              PostRepository postRepository) {
        this.repostRepository = repostRepository;
        this.postRepository = postRepository;
    }

    @Override
    public void repost(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (repostRepository.existsByUserIdAndOriginalPostId(userId, postId)) {
            throw new BadRequestException("You already reposted this post");
        }

        Repost repost = Repost.builder()
            .userId(userId)
            .originalPostId(postId)
            .build();
        repostRepository.save(repost);

        post.setRepostCount(post.getRepostCount() + 1);
        postRepository.save(post);

        log.info("User {} reposted post {}", userId, postId);
    }

    @Override
    public void removeRepost(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new ResourceNotFoundException("Post", "id", postId));

        if (!repostRepository.existsByUserIdAndOriginalPostId(userId, postId)) {
            throw new BadRequestException("You have not reposted this post");
        }

        repostRepository.deleteByUserIdAndOriginalPostId(userId, postId);

        post.setRepostCount(Math.max(0, post.getRepostCount() - 1));
        postRepository.save(post);

        log.info("User {} removed repost of post {}", userId, postId);
    }
}
