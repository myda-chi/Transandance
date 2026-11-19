CREATE TABLE content.islands (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug VARCHAR(50) NOT NULL UNIQUE,
    display_order INTEGER NOT NULL UNIQUE,

    CONSTRAINT islands_slug_check
        CHECK (slug IN ('maths', 'vocabulary', 'culture')),

    CONSTRAINT islands_display_order_check
        CHECK (display_order > 0)
);