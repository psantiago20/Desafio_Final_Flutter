package com.pitaya.shared.event.events;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PostCreatedEvent implements Serializable {

    private static final long serialVersionUID = 1L;

    private String postId;
    private String userId;
    private String content;
    private List<String> mediaUrls;
    private List<String> tags;
    private String visibility;
}
