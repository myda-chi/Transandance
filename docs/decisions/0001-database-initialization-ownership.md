# Database initialization ownership

- **Status:** Accepted

## Context

The initial architecture proposed mounting an SQL script into the PostgreSQL
container to create the application schemas and service-specific database
users. PostgreSQL's container entrypoint runs such initialization scripts only
when it creates a new database cluster. This ties application setup to the
database container's first-start behavior and makes it easy to overlook when
provisioning needs to change.

## Decision

The migration container owns application-level database initialization: it
creates the `identity`, `content`, and `game` schemas and their respective
service users. PostgreSQL remains responsible for starting the database and
creating the configured initial database and administrative user. The
application services start only after the migration container completes
successfully.

## Consequences

- Database setup and schema migrations have one explicit owner and run in a
  defined order before application services start.
- Application-specific setup is no longer coupled to whether PostgreSQL is
  starting with a fresh or existing data volume.
- The migration container needs administrative database credentials to
  provision schemas and users; these credentials must be supplied through the
  deployment environment and kept secret.
