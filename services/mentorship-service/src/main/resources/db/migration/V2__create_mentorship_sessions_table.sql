CREATE TABLE mentorship_sessions (
    id              UUID PRIMARY KEY,
    mentorship_id   UUID NOT NULL REFERENCES mentorships(id) ON DELETE CASCADE,
    title           VARCHAR(255) NOT NULL,
    description     TEXT,
    scheduled_at    TIMESTAMP NOT NULL,
    duration_minutes INTEGER NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    meeting_link    VARCHAR(500),
    mentor_notes    TEXT,
    mentee_feedback TEXT,
    rating          INTEGER CHECK (rating >= 1 AND rating <= 5),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_mentorship_id ON mentorship_sessions(mentorship_id);
CREATE INDEX idx_sessions_mentorship_status ON mentorship_sessions(mentorship_id, status);
CREATE INDEX idx_sessions_scheduled_at ON mentorship_sessions(scheduled_at);
