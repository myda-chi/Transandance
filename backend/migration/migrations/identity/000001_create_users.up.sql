CREATE SCHEMA IF NOT EXISTS identity;

CREATE TABLE identity.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role VARCHAR(10) NOT NULL,
    email VARCHAR(255),
    username VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'ACTIVE',
    deactivation_source VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Valid roles
    CONSTRAINT users_role_check
        CHECK (role IN ('PARENT', 'CHILD', 'ADMIN')),

    -- Valid account statuses
    CONSTRAINT user_status_check
        CHECK (status IN ('ACTIVE', 'INACTIVE')),

    -- Parent and admin accounts use emails.
    -- Child accounts use username.
    CONSTRAINT users_account_identifier_check
        CHECK (
            (role IN ('PARENT', 'ADMIN')
                AND email IS NOT NULL
                AND username IS NULL)
            OR
            (role = 'CHILD'
                AND email IS NULL
                AND username IS NOT NULL)
        ),

    -- Accounts status and deactivation reason must agree.
    CONSTRAINT users_deactivation_check
        CHECK (
            (status = 'ACTIVE' AND deactivation_source IS NULL)
            OR
            (
                status = 'INACTIVE'
                AND deactivation_source IN (
                    'SELF',
                    'PARENT',
                    'PARENT_ACCOUNT',
                    'ADMIN'
                )
            )
        )
);

-- Emails must be unique, ignore letter case.
CREATE UNIQUE INDEX users_email_unique_idx
    ON identity.users (LOWER(email))
    WHERE email IS NOT NULL;

-- Usernames must be unique, ignore letter case
CREATE UNIQUE INDEX users_username_unique_idx
    ON identity.users (LOWER(username))
    WHERE username IS NOT NULL;