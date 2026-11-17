CREATE TABLE game.answer_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    player_user_id UUID NOT NULL,
    question_id UUID NOT NULL,
    selected_option_id UUID NOT NULL,
    is_correct BOOLEAN NOT NULL,
    response_time_ms INTEGER NOT NULL,
    answered_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT answer_submissions_session_fk
        FOREIGN KEY (session_id)
        REFERENCES game.quiz_sessions(id),

    CONSTRAINT answer_submissions_response_time_check
        CHECK (response_time_ms >= 0),

    CONSTRAINT answer_submissions_unique_answer
        UNIQUE (session_id, player_user_id, question_id)
);