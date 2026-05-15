CREATE TABLE user_badges (
    user_id     UUID NOT NULL,
    badge_id    UUID NOT NULL,
    unlocked_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX idx_user_badges_badge_id ON user_badges(badge_id);
