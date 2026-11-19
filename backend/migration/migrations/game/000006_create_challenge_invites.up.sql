CREATE TABLE game.challenge_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID NOT NULL,
    invitee_user_id UUID NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMPTZ,

    CONSTRAINT challenge_invites_challenge_fk
        FOREIGN KEY (challenge_id)
        REFERENCES game.challenges(id),

    CONSTRAINT challenge_invites_status_check
        CHECK (status IN (
            'PENDING',
            'ACCEPTED',
            'DECLINED',
            'EXPIRED'
        )),

    CONSTRAINT challenge_invites_responded_at_check
        CHECK (
            (status IN ('ACCEPTED', 'DECLINED') AND responded_at IS NOT NULL)
            OR
            (status IN ('PENDING', 'EXPIRED') AND responded_at IS NULL)
        ),

    CONSTRAINT challenge_invites_unique_invitee
        UNIQUE (challenge_id, invitee_user_id)
);

CREATE INDEX challenge_invites_invitee_user_id_idx
    ON game.challenge_invites (invitee_user_id);

CREATE INDEX challenge_invites_challenge_status_idx
    ON game.challenge_invites (challenge_id, status);