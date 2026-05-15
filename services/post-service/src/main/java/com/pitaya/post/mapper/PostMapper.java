package com.pitaya.post.mapper;

import com.pitaya.post.dto.request.CreatePostRequest;
import com.pitaya.post.dto.response.PostResponse;
import com.pitaya.post.dto.response.PostSummaryResponse;
import com.pitaya.post.entity.Post;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface PostMapper {

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "userId", ignore = true)
    @Mapping(target = "isPinned", constant = "false")
    @Mapping(target = "likeCount", constant = "0")
    @Mapping(target = "commentCount", constant = "0")
    @Mapping(target = "repostCount", constant = "0")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    Post toEntity(CreatePostRequest request);

    @Mapping(target = "authorDisplayName", ignore = true)
    @Mapping(target = "authorUsername", ignore = true)
    @Mapping(target = "authorAvatar", ignore = true)
    @Mapping(target = "authorBio", ignore = true)
    @Mapping(target = "isLiked", ignore = true)
    @Mapping(target = "isReposted", ignore = true)
    @Mapping(target = "hashtags", ignore = true)
    PostResponse toResponse(Post post);

    @Mapping(target = "authorDisplayName", ignore = true)
    @Mapping(target = "authorUsername", ignore = true)
    @Mapping(target = "authorAvatar", ignore = true)
    @Mapping(target = "isLiked", ignore = true)
    @Mapping(target = "isReposted", ignore = true)
    @Mapping(target = "hashtags", ignore = true)
    PostSummaryResponse toSummaryResponse(Post post);
}
