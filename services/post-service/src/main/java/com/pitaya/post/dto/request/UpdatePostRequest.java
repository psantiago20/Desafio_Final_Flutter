package com.pitaya.post.dto.request;

import com.pitaya.post.entity.Visibility;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UpdatePostRequest {

    @Size(max = 5000, message = "Content must be at most 5000 characters")
    private String content;

    private Visibility visibility;
}
