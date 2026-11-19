CREATE TABLE game.quiz_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mode VARCHAR(20) NOT NULL,
    island_id UUID NOT NULL,
    level_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,

    CONSTRAINT quiz_sessions_mode_check
        CHECK (mode IN ('SOLO', 'CHALLENGE')),

    CONSTRAINT quiz_sessions_status_check
        CHECK (status IN ('ACTIVE', 'COMPLETED', 'ABANDONED')),

     -- Completed sessions must have a completion timestamp.
    CONSTRAINT quiz_sessions_completed_at_check
        CHECK (
            status <> 'COMPLETED'
            OR completed_at IS NOT NULL
        )
);