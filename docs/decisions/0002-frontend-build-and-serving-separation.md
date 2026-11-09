# Frontend build and serving separation

- **Status:** Accepted

## Context

The frontend's static files need to be built for deployment and then served to
users. Combining those responsibilities in one container would couple the
frontend build toolchain to the public web server.

## Decision

Use a one-shot frontend container to build the static frontend files and write
them to a shared volume. The container exits after a successful build. Serve
those files with the official Nginx image, which mounts the volume read-only
alongside the project's Nginx configuration. Nginx starts only after the
frontend build completes successfully.

## Consequences

- The frontend build toolchain is isolated from the public web server.
- Nginx remains responsible for serving static files, TLS, and reverse-proxy
  routing; it does not build the frontend.
- The deployment must share the build output with Nginx and enforce the build
  before Nginx starts.
