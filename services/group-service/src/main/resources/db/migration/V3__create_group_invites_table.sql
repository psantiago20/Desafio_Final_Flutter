CREATE TABLE group_invites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    invited_by UUID NOT NULL,
    invited_user UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    responded_at TIMESTAMP
);

CREATE INDEX idx_group_invites_group_id ON group_invites(group_id);
CREATE INDEX idx_group_invites_invited_user ON group_invites(invited_user);
CREATE INDEX idx_group_invites_status ON group_invites(status);
