# Database migrations

Versioned SQL migrations are separated by service. Each service migrates only
its own schema; pair each `.up.sql` migration with a `.down.sql` migration.
