CREATE TABLE xp_transactions (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL,
    amount          INTEGER NOT NULL,
    reason          VARCHAR(255) NOT NULL,
    reference_id    VARCHAR(100),
    reference_type  VARCHAR(50),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_xp_transactions_user_id ON xp_transactions(user_id);
CREATE INDEX idx_xp_transactions_created_at ON xp_transactions(created_at DESC);
CREATE INDEX idx_xp_transactions_user_created ON xp_transactions(user_id, created_at DESC);
