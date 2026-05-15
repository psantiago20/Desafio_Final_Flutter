CREATE TABLE follows (
    follower_id  UUID NOT NULL,
    following_id UUID NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id)
);

CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id);
