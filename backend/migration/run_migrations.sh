#!/bin/sh

set -eu

echo "======================================"
echo " Starting database initialization"
echo "======================================"

# ======================================
# 1. WAIT FOR POSTGRESQL
# ======================================

echo "Waiting for PostgreSQL..."

until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$POSTGRES_USER"; do
    sleep 2
done

echo "PostgreSQL is ready!"

# ======================================
# 2. INITIALIZE DATABASE
# ======================================

echo "Initializing database schemas and users..."

PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -v identity_user="$IDENTITY_DB_USER" \
    -v identity_password="$IDENTITY_DB_PASSWORD" \
    -v content_user="$CONTENT_DB_USER" \
    -v content_password="$CONTENT_DB_PASSWORD" \
    -v game_user="$GAME_DB_USER" \
    -v game_password="$GAME_DB_PASSWORD" \
    -f /migrations/init/001_init_database.sql

echo "Database initialization completed!"

# ======================================
# 3. APPLY SERVICE MIGRATIONS
# ======================================

run_migrations() {
    SERVICE="$1"
    DB_USER="$2"
    DB_PASSWORD="$3"
    DB_SCHEMA="$4"

    ENCODED_PASSWORD=$(jq -rn --arg password "$DB_PASSWORD" '$password | @uri')

    echo "Applying ${SERVICE} migrations..."

    migrate \
        -path "/migrations/${SERVICE}" \
        -database "postgres://${DB_USER}:${ENCODED_PASSWORD}@${DB_HOST}:${DB_PORT}/${POSTGRES_DB}?search_path=${DB_SCHEMA}&sslmode=disable" \
        -verbose up

    echo "${SERVICE} migrations completed!"
}


# IDENTITY
run_migrations \
    identity \
    "$IDENTITY_DB_USER" \
    "$IDENTITY_DB_PASSWORD" \
    "$IDENTITY_DB_SCHEMA"

# CONTENT
run_migrations \
    content \
    "$CONTENT_DB_USER" \
    "$CONTENT_DB_PASSWORD" \
    "$CONTENT_DB_SCHEMA"

# GAME
run_migrations \
    game \
    "$GAME_DB_USER" \
    "$GAME_DB_PASSWORD" \
    "$GAME_DB_SCHEMA"


# ======================================
# 4. FINISH
# ======================================

echo "======================================"
echo " All migrations completed successfully"
echo "======================================"