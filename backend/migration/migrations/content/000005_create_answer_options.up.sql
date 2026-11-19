CREATE TABLE content.answer_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL,
    display_order INTEGER NOT NULL,
    is_correct BOOLEAN NOT NULL,

    CONSTRAINT answer_options_question_id_fkey
        FOREIGN KEY (question_id)
        REFERENCES content.questions (id)
        ON DELETE NO ACTION,

    CONSTRAINT answer_options_display_order_check
        CHECK (display_order > 0),

    CONSTRAINT answer_options_question_display_order_unique
        UNIQUE (question_id, display_order)
);

CREATE UNIQUE INDEX answer_options_one_correct_per_question_idx
    ON content.answer_options (question_id)
    WHERE is_correct = TRUE;