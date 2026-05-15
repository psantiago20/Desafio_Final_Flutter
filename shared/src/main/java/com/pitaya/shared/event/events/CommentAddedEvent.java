package com.pitaya.shared.event.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommentAddedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String commentId;
    private String postId;
    private String userId;
    private String content;
    private String parentCommentId;
}
