CREATE TABLE content.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_id UUID NOT NULL,
    difficulty INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT questions_level_id_fkey
        FOREIGN KEY (level_id)
        REFERENCES content.levels (id),

    CONSTRAINT questions_difficulty_check
        CHECK (difficulty > 0)
);

CREATE INDEX questions_level_id_idx
    ON content.questions (level_id);