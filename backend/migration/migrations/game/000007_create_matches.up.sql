CREATE TABLE game.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL,
    session_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,

    CONSTRAINT matches_challenge_fk
        FOREIGN KEY (challenge_id)
        REFERENCES game.challenges(id),

    CONSTRAINT matches_session_fk
        FOREIGN KEY (session_id)
        REFERENCES game.quiz_sessions(id),

    CONSTRAINT matches_status_check
        CHECK (status IN (
            'ACTIVE',
            'COMPLETED',
            'ABANDONED'
        )),

    CONSTRAINT matches_unique_challenge
        UNIQUE (challenge_id),

    CONSTRAINT matches_unique_session
        UNIQUE (session_id)
);