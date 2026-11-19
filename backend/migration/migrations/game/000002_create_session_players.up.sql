CREATE TABLE game.session_players (
    session_id UUID NOT NULL,
    player_user_id UUID NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    result VARCHAR(10),

    CONSTRAINT session_players_pk
        PRIMARY KEY (session_id, player_user_id),

    CONSTRAINT session_players_session_fk
        FOREIGN KEY (session_id)
        REFERENCES game.quiz_sessions(id),

    CONSTRAINT session_players_score_check
        CHECK (score >= 0),

    CONSTRAINT session_players_result_check
        CHECK (result IN ('WIN', 'LOSS', 'DRAW') OR result IS NULL)
);

CREATE INDEX session_players_player_user_idx
    ON game.session_players (player_user_id);