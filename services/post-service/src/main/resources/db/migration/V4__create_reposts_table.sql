CREATE TABLE reposts (
    id                  UUID PRIMARY KEY,
    user_id             UUID NOT NULL,
    original_post_id    UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, original_post_id)
);

CREATE INDEX idx_reposts_original_post_id ON reposts(original_post_id);
CREATE INDEX idx_reposts_user_id ON reposts(user_id);
CREATE INDEX idx_reposts_user_post ON reposts(user_id, original_post_id);
