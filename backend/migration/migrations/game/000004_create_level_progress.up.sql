CREATE TABLE game.level_progress (
    player_user_id UUID NOT NULL,
    level_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'LOCKED',
    best_score INTEGER NOT NULL DEFAULT 0,
    attempt_count INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ,

    CONSTRAINT level_progress_pk
        PRIMARY KEY (player_user_id, level_id),

    CONSTRAINT level_progress_status_check
        CHECK (status IN ('LOCKED', 'UNLOCKED', 'COMPLETED')),

    CONSTRAINT level_progress_best_score_check
        CHECK (best_score >= 0),

    CONSTRAINT level_progress_attempt_count_check
        CHECK (attempt_count >= 0)
);