CREATE TABLE content.option_translations (
    option_id UUID NOT NULL,
    locale VARCHAR(10) NOT NULL,
    text TEXT NOT NULL,

    CONSTRAINT option_translations_pkey
        PRIMARY KEY (option_id, locale),

    CONSTRAINT option_translations_option_id_fkey
        FOREIGN KEY (option_id)
        REFERENCES content.answer_options (id)
        ON DELETE NO ACTION,

    CONSTRAINT option_translations_locale_check
        CHECK (length(trim(locale)) > 0),

    CONSTRAINT option_translations_text_check
        CHECK (length(trim(text)) > 0)
);