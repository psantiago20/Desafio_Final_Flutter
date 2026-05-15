CREATE TABLE mentorships (
    id              UUID PRIMARY KEY,
    mentor_id       UUID NOT NULL,
    mentee_id       UUID NOT NULL,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_date      TIMESTAMP,
    end_date        TIMESTAMP,
    max_sessions    INTEGER,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mentorships_mentor_id ON mentorships(mentor_id);
CREATE INDEX idx_mentorships_mentee_id ON mentorships(mentee_id);
CREATE INDEX idx_mentorships_status ON mentorships(status);
CREATE INDEX idx_mentorships_mentor_status ON mentorships(mentor_id, status);
CREATE INDEX idx_mentorships_mentee_status ON mentorships(mentee_id, status);
