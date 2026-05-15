CREATE TABLE badges (
    id          UUID PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(500) NOT NULL,
    icon_url    VARCHAR(500),
    category    VARCHAR(50) NOT NULL,
    xp_required INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_badges_category ON badges(category);
CREATE INDEX idx_badges_xp_required ON badges(xp_required);
