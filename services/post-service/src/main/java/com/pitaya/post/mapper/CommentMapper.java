package com.pitaya.post.mapper;

import com.pitaya.post.dto.response.CommentResponse;
import com.pitaya.post.entity.Comment;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface CommentMapper {

    @Mapping(target = "authorDisplayName", ignore = true)
    @Mapping(target = "authorUsername", ignore = true)
    @Mapping(target = "authorAvatar", ignore = true)
    CommentResponse toResponse(Comment comment);
}
