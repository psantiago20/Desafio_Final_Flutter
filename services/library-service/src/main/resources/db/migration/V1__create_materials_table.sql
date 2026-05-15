CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(500) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL,
    url VARCHAR(2048),
    file_size BIGINT,
    file_type VARCHAR(100),
    uploader_id UUID NOT NULL,
    group_id UUID,
    tags TEXT[] DEFAULT '{}',
    download_count INTEGER NOT NULL DEFAULT 0,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_materials_type ON materials(type);
CREATE INDEX idx_materials_uploader_id ON materials(uploader_id);
CREATE INDEX idx_materials_group_id ON materials(group_id);
CREATE INDEX idx_materials_is_public ON materials(is_public);
CREATE INDEX idx_materials_download_count ON materials(download_count DESC);
CREATE INDEX idx_materials_created_at ON materials(created_at DESC);
CREATE INDEX idx_materials_title ON materials(title);

CREATE INDEX idx_materials_tags ON materials USING GIN(tags);
