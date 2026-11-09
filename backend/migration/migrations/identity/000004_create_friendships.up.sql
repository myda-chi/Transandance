CREATE TABLE identity.friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    requester_id UUID NOT NULL,
    addressee_id UUID NOT NULL,

    status VARCHAR(10) NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT friendships_requester_fk
        FOREIGN KEY (requester_id)
        REFERENCES identity.users(id),

    CONSTRAINT friendships_addressee_fk
        FOREIGN KEY (addressee_id)
        REFERENCES identity.users(id),

    CONSTRAINT friendships_no_self_friendship
        CHECK (requester_id <> addressee_id),

    CONSTRAINT friendships_status_check
        CHECK (
            status IN (
                'PENDING',
                'ACCEPTED',
                'DECLINED',
                'REMOVED'
            )
        )
);

-- Prevent duplicate friendship records regardless of request direction.
CREATE UNIQUE INDEX friendships_pair_unique_idx
ON identity.friendships (
    LEAST(requester_id, addressee_id),
    GREATEST(requester_id, addressee_id)
);

-- Support queries involving either participant.
CREATE INDEX friendships_requester_idx
    ON identity.friendships (requester_id);

CREATE INDEX friendships_addressee_idx
    ON identity.friendships (addressee_id);