CREATE TABLE user_gamification (
    id          UUID PRIMARY KEY,
    user_id     UUID NOT NULL UNIQUE,
    xp_points   INTEGER NOT NULL DEFAULT 0,
    level       INTEGER NOT NULL DEFAULT 1,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_gamification_user_id ON user_gamification(user_id);
CREATE INDEX idx_user_gamification_xp_points ON user_gamification(xp_points DESC);
