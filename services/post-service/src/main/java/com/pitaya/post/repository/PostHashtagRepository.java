package com.pitaya.post.repository;

import com.pitaya.post.entity.PostHashtag;
import com.pitaya.post.entity.PostHashtagId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PostHashtagRepository extends JpaRepository<PostHashtag, PostHashtagId> {

    List<PostHashtag> findByHashtagId(UUID hashtagId);

    List<PostHashtag> findByPostId(UUID postId);

    void deleteByPostId(UUID postId);
}
