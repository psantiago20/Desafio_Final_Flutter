CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    banner_url VARCHAR(512),
    category VARCHAR(100),
    visibility VARCHAR(20) NOT NULL DEFAULT 'PUBLIC',
    owner_id UUID NOT NULL,
    member_count INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_groups_owner_id ON groups(owner_id);
CREATE INDEX idx_groups_category ON groups(category);
CREATE INDEX idx_groups_is_active ON groups(is_active);
CREATE INDEX idx_groups_name ON groups(name);
