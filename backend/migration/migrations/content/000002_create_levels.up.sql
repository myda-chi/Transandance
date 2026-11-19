CREATE TABLE content.levels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    island_id UUID NOT NULL,
    slug VARCHAR(100) NOT NULL,
    display_order INTEGER NOT NULL,
    difficulty INTEGER NOT NULL,

    -- Each level belongs to an existing island.
    CONSTRAINT levels_island_id_fkey
        FOREIGN KEY (island_id)
        REFERENCES content.islands (id),

    -- Every level has a globally unique slug.
    CONSTRAINT levels_slug_unique
        UNIQUE (slug),

    -- Display order must be unique within its island.
    CONSTRAINT levels_island_display_order_unique
        UNIQUE (island_id, display_order),

    -- Display order must be a positive number.
    CONSTRAINT levels_display_order_check
        CHECK (display_order > 0),

    -- Difficulty must be a positive number.
    CONSTRAINT levels_difficulty_check
        CHECK (difficulty > 0)
);