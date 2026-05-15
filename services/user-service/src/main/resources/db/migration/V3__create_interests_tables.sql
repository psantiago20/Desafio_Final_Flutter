CREATE TABLE interests (
    id       UUID PRIMARY KEY,
    name     VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(100),
    icon     VARCHAR(50)
);

CREATE TABLE user_interests (
    user_id     UUID NOT NULL,
    interest_id UUID NOT NULL,
    PRIMARY KEY (user_id, interest_id)
);

CREATE INDEX idx_user_interests_user_id ON user_interests(user_id);
CREATE INDEX idx_user_interests_interest_id ON user_interests(interest_id);
