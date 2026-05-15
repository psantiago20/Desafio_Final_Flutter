package com.pitaya.post.dto.request;

import com.pitaya.post.entity.Visibility;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreatePostRequest {

    @NotBlank(message = "Content is required")
    @Size(max = 5000, message = "Content must be at most 5000 characters")
    private String content;

    @Size(max = 500, message = "Image URL must be at most 500 characters")
    private String imageUrl;

    @Builder.Default
    private Visibility visibility = Visibility.PUBLIC;
}
