CREATE TABLE profiles (
    id              UUID PRIMARY KEY,
    user_id         UUID NOT NULL UNIQUE,
    avatar          VARCHAR(500),
    banner          VARCHAR(500),
    bio             TEXT,
    location        VARCHAR(255),
    institution     VARCHAR(255),
    course          VARCHAR(255),
    semester        VARCHAR(50),
    research_line   VARCHAR(500),
    lattes_url      VARCHAR(500),
    orcid           VARCHAR(30),
    github_url      VARCHAR(500),
    linkedin_url    VARCHAR(500),
    profile_complete BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_institution ON profiles(institution);
