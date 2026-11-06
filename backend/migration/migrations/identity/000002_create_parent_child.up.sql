CREATE TABLE identity.parent_child (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    parent_user_id UUID NOT NULL,
    child_user_id UUID NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT parent_child_parent_fk
        FOREIGN KEY (parent_user_id)
        REFERENCES identity.users(id),

    CONSTRAINT parent_child_child_fk
        FOREIGN KEY (child_user_id)
        REFERENCES identity.users(id),

    CONSTRAINT parent_child_unique_child
        UNIQUE (child_user_id),

    CONSTRAINT parent_child_no_self_parent
        CHECK (parent_user_id <> child_user_id)
);

CREATE INDEX parent_child_parent_idx
    ON identity.parent_child (parent_user_id);