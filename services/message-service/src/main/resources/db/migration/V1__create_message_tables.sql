CREATE TABLE conversations (
    id UUID PRIMARY KEY,
    type VARCHAR(32) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    created_by UUID
);

CREATE TABLE conversation_participants (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    joined_at TIMESTAMPTZ,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    notification_setting VARCHAR(32),
    last_read_at TIMESTAMPTZ,
    CONSTRAINT uq_conversation_participant UNIQUE (conversation_id, user_id)
);

CREATE TABLE messages (
    id UUID PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES conversations (id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    content TEXT NOT NULL,
    media_type VARCHAR(32),
    media_url VARCHAR(2048),
    created_at TIMESTAMPTZ,
    edited_at TIMESTAMPTZ,
    is_edited BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(32)
);

CREATE INDEX idx_conversation_participants_conversation ON conversation_participants (conversation_id);
CREATE INDEX idx_messages_conversation ON messages (conversation_id);
CREATE INDEX idx_messages_sender ON messages (sender_id);
