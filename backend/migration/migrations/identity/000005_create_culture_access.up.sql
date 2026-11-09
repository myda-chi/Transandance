CREATE TABLE identity.culture_access (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_user_id UUID NOT NULL,
    topic_id UUID NOT NULL,
    allowed BOOLEAN NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT culture_access_child_fk
        FOREIGN KEY (child_user_id)
        REFERENCES identity.users(id),

    CONSTRAINT culture_access_child_topic_unique
        UNIQUE (child_user_id, topic_id)
);