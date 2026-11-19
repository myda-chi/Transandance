CREATE TABLE game.challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenger_id UUID NOT NULL,
    level_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT challenges_status_check
        CHECK (status IN (
            'PENDING',
            'STARTED',
            'COMPLETED',
            'CANCELLED',
            'EXPIRED'
        )),

    -- A challenge cannot expire before it is created.
    CONSTRAINT challenges_expiration_check
        CHECK (expires_at >= created_at)
);

CREATE INDEX challenges_challenger_id_idx
    ON game.challenges (challenger_id);

CREATE INDEX challenges_status_expires_at_idx
    ON game.challenges (status, expires_at);