CREATE TABLE notification_preferences (
    id                UUID PRIMARY KEY,
    user_id           UUID NOT NULL UNIQUE,
    email_likes       BOOLEAN NOT NULL DEFAULT TRUE,
    email_comments    BOOLEAN NOT NULL DEFAULT TRUE,
    email_follows     BOOLEAN NOT NULL DEFAULT TRUE,
    email_mentorship  BOOLEAN NOT NULL DEFAULT TRUE,
    email_groups      BOOLEAN NOT NULL DEFAULT TRUE,
    email_badges      BOOLEAN NOT NULL DEFAULT TRUE,
    push_enabled      BOOLEAN NOT NULL DEFAULT TRUE,
    in_app_enabled    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_preferences_user_id ON notification_preferences(user_id);
