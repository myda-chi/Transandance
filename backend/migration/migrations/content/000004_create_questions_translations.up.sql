CREATE TABLE content.question_translations (
    question_id UUID NOT NULL,
    locale VARCHAR(10) NOT NULL,
    prompt TEXT NOT NULL,

    CONSTRAINT question_translations_pkey
        PRIMARY KEY (question_id, locale),

    CONSTRAINT question_translations_question_id_fkey
        FOREIGN KEY (question_id)
        REFERENCES content.questions (id)
        ON DELETE NO ACTION,

    CONSTRAINT question_translations_locale_check
        CHECK (length(trim(locale)) > 0),

    CONSTRAINT question_translations_prompt_check
        CHECK (length(trim(prompt)) > 0)
);