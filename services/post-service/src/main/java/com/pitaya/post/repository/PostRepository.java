package com.pitaya.post.repository;

import com.pitaya.post.entity.Post;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PostRepository extends JpaRepository<Post, UUID> {

    Page<Post> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    @Query("SELECT p FROM Post p WHERE p.userId = :userId " +
           "AND (:currentUserId = :userId OR p.visibility = 'PUBLIC' " +
           "OR (p.visibility = 'FOLLOWERS_ONLY' AND :currentUserId IN :followingIds)) " +
           "ORDER BY p.createdAt DESC")
    Page<Post> findUserPostsWithVisibility(
        @Param("userId") UUID userId,
        @Param("currentUserId") UUID currentUserId,
        @Param("followingIds") List<UUID> followingIds,
        Pageable pageable);

    @Query("SELECT p FROM Post p WHERE " +
           "(p.visibility = 'PUBLIC') " +
           "OR (p.visibility = 'FOLLOWERS_ONLY' AND p.userId IN :followingIds) " +
           "OR (p.userId = :currentUserId) " +
           "ORDER BY p.createdAt DESC")
    Page<Post> findAccessiblePosts(
        @Param("currentUserId") UUID currentUserId,
        @Param("followingIds") List<UUID> followingIds,
        Pageable pageable);

    @Query("SELECT p FROM Post p WHERE " +
           "p.visibility = 'PUBLIC' AND p.userId NOT IN :followingIds " +
           "AND p.userId <> :currentUserId " +
           "ORDER BY (p.likeCount + p.commentCount + p.repostCount) DESC, p.createdAt DESC")
    Page<Post> findExplorePosts(
        @Param("currentUserId") UUID currentUserId,
        @Param("followingIds") List<UUID> followingIds,
        Pageable pageable);

    @Query("SELECT p FROM Post p JOIN PostHashtag ph ON ph.id.postId = p.id " +
           "JOIN Hashtag h ON h.id = ph.id.hashtagId " +
           "WHERE LOWER(h.name) = LOWER(:hashtag) AND " +
           "(p.visibility = 'PUBLIC' " +
           "OR (p.visibility = 'FOLLOWERS_ONLY' AND p.userId IN :followingIds) " +
           "OR (p.userId = :currentUserId)) " +
           "ORDER BY p.createdAt DESC")
    Page<Post> findByHashtagWithAccess(
        @Param("hashtag") String hashtag,
        @Param("currentUserId") UUID currentUserId,
        @Param("followingIds") List<UUID> followingIds,
        Pageable pageable);

    Page<Post> findByUserIdAndIsPinnedTrue(UUID userId, Pageable pageable);

    long countByUserId(UUID userId);
}
