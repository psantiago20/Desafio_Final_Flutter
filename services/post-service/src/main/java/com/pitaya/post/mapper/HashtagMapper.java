package com.pitaya.post.mapper;

import com.pitaya.post.dto.response.HashtagResponse;
import com.pitaya.post.entity.Hashtag;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

@Mapper(
    componentModel = "spring",
    unmappedTargetPolicy = ReportingPolicy.IGNORE
)
public interface HashtagMapper {

    @Mapping(target = "postCount", source = "usageCount")
    HashtagResponse toResponse(Hashtag hashtag);
}
