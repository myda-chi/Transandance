FROM alpine:3.24

ARG MIGRATE_VERSION=4.20.1

ARG TARGETARCH

RUN apk add --no-cache ca-certificates postgresql-client jq \
    && wget -q \
       "https://github.com/golang-migrate/migrate/releases/download/v${MIGRATE_VERSION}/migrate.linux-${TARGETARCH}.tar.gz" \
       -O /tmp/migrate.tar.gz \
    && tar -xzf /tmp/migrate.tar.gz -C /usr/local/bin migrate \
    && rm /tmp/migrate.tar.gz

WORKDIR /app

COPY backend/migration/run_migrations.sh /app/run_migrations.sh
COPY backend/migration/migrations/ /migrations/

RUN chmod +x /app/run_migrations.sh

ENTRYPOINT ["/bin/sh", "/app/run_migrations.sh"]