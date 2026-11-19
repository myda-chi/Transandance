-- Stop immediately if a command fails.
\set ON_ERROR_STOP on


-- ==========================================
-- 1. CREATE DATABASE SERVICE USERS
-- ==========================================

-- IDENTITY
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
    :'identity_user',
    :'identity_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'identity_user'
)
\gexec

-- CONTENT
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
    :'content_user',
    :'content_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'content_user'
)
\gexec

-- GAME
SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS',
    :'game_user',
    :'game_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'game_user'
)
\gexec


-- ==========================================
-- 2. ENSURE SERVICE USERS HAVE RESTRICTED PRIVILEGES
-- ==========================================

ALTER ROLE :"identity_user"
    WITH LOGIN PASSWORD :'identity_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

ALTER ROLE :"content_user"
    WITH LOGIN PASSWORD :'content_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;

ALTER ROLE :"game_user"
    WITH LOGIN PASSWORD :'game_password'
    NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;


-- ==========================================
-- 3. CREATE DATABASE SCHEMAS
-- ==========================================

CREATE SCHEMA IF NOT EXISTS identity AUTHORIZATION :"identity_user";
CREATE SCHEMA IF NOT EXISTS content AUTHORIZATION :"content_user";
CREATE SCHEMA IF NOT EXISTS game AUTHORIZATION :"game_user";


-- ==========================================
-- 4. ENSURE CORRECT SCHEMA OWNERSHIP
-- ==========================================

ALTER SCHEMA identity OWNER TO :"identity_user";
ALTER SCHEMA content OWNER TO :"content_user";
ALTER SCHEMA game OWNER TO :"game_user";


-- ==========================================
-- 5. RESTRICT SCHEMA ACCESS
-- ==========================================

-- Remove default access through PUBLIC.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

REVOKE ALL ON SCHEMA identity, content, game FROM PUBLIC;

-- Identity must not access Content or Game.
REVOKE ALL ON SCHEMA content, game FROM :"identity_user";

-- Content must not access Identity or Game.
REVOKE ALL ON SCHEMA identity, game FROM :"content_user";

-- Game must not access Identity or Content.
REVOKE ALL ON SCHEMA identity, content FROM :"game_user";


-- ==========================================
-- 6. GRANT ACCESS TO EACH SERVICE'S SCHEMA
-- ==========================================

GRANT USAGE, CREATE ON SCHEMA identity TO :"identity_user";
GRANT USAGE, CREATE ON SCHEMA content TO :"content_user";
GRANT USAGE, CREATE ON SCHEMA game TO :"game_user";

-- ==========================================
-- 7. SET DEFAULT SEARCH PATH
-- ==========================================

ALTER ROLE :"identity_user" SET search_path TO identity;
ALTER ROLE :"content_user" SET search_path TO content;
ALTER ROLE :"game_user" SET search_path TO game;