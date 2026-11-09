# Frontend Development Guide

Welcome to the Transcendence frontend!

This document explains the frontend technology stack, the existing development environment, dependency management, and how the frontend integrates with the project's Docker infrastructure.

The frontend application is developed independently, while its production build and delivery are integrated into the project's Docker environment.

---

## 1. Technology Stack

The frontend uses the following technologies:

| Technology | Purpose |
|---|---|
| React | Building the user interface |
| TypeScript | Type-safe application development |
| Vite | Frontend development and production build tool |
| Tailwind CSS | Utility-first CSS framework |
| Node.js | JavaScript runtime used by the build environment |
| npm | Dependency and package management |
| Docker | Isolated frontend build environment |
| Nginx | Serving the compiled frontend application |

### Important

Node.js and npm do not need to be installed on the host machine.

The frontend build environment uses the official `node:24-alpine` Docker image.

---

## 2. Directory Structure

The frontend directory contains the application, its dependencies, and its build configuration.

```text
frontend/
├── Dockerfile
├── .dockerignore
├── package.json
├── package-lock.json
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
│
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── index.css
    └── ...
```

The files listed under `src/` represent the application source structure to be implemented by the frontend developers.

### Existing configuration files

| File | Responsibility |
|---|---|
| `Dockerfile` | Defines the frontend build environment |
| `.dockerignore` | Excludes unnecessary files from the Docker build context |
| `package.json` | Declares dependencies and npm scripts |
| `package-lock.json` | Locks the resolved dependency versions |
| `vite.config.ts` | Configures Vite |
| `tailwind.config.js` | Configures Tailwind CSS |
| `postcss.config.js` | Configures PostCSS and Autoprefixer |

---

## 3. Dependency Management

Frontend dependencies are managed through npm.

Two files are particularly important:

- `package.json`: declares the dependencies used by the project.
- `package-lock.json`: records the exact resolved dependency tree.

**Both files must be committed to Git.**

### Installing a new dependency

Run npm through Docker instead of installing Node.js locally.

From the project root:

```bash
docker run --rm \
  -v "$(pwd)/frontend:/app" \
  -w /app \
  node:24-alpine \
  npm install <package-name>
```

For development dependencies:

```bash
docker run --rm \
  -v "$(pwd)/frontend:/app" \
  -w /app \
  node:24-alpine \
  npm install -D <package-name>
```

### Removing a dependency

```bash
docker run --rm \
  -v "$(pwd)/frontend:/app" \
  -w /app \
  node:24-alpine \
  npm uninstall <package-name>
```

These commands update the dependency manifests and lockfile.

Remember to commit both files whenever dependencies change.

### Installing dependencies from the lockfile

The production Docker build uses:

```bash
npm ci
```

Unlike `npm install`, `npm ci` installs dependencies according to the existing lockfile without modifying it.

This ensures consistent dependency installation across environments.

---

## 4. Frontend Build Architecture

The frontend production build is handled by a dedicated Docker service:

`frontend-build`

Its Docker image is defined in `frontend/Dockerfile`.

The build process follows these steps:

1. Docker creates the frontend build environment using Node.js.
2. Dependency manifests are copied into the image.
3. Dependencies are installed using `npm ci`.
4. Frontend application source files are copied into the image.
5. Vite generates the production build.
6. The compiled files are written to `/output`.

The build output is stored in a shared Docker volume:

`frontend_dist`

### Nginx integration

Nginx mounts the shared volume as read-only:

```yaml
- frontend_dist:/usr/share/nginx/html:ro
```

Nginx is responsible for serving the compiled frontend application.

**Important architectural distinction:**

- The frontend builder compiles the application.
- The shared volume stores the compiled output.
- Nginx serves the compiled files.
- Nginx does not install frontend dependencies or build the application.

The frontend builder must complete successfully before Nginx starts.

---

## 5. npm Scripts

The project currently defines the following scripts in `package.json`:

| Command | Purpose |
|---|---|
| `npm run dev` | Starts the Vite development server |
| `npm run build` | Generates the production build |

The production build is invoked automatically by the frontend Docker builder.

The current Docker integration is designed around production builds served through Nginx. A separate Docker-based development-server workflow is not part of the current configuration.

---

## 6. Git Conventions

The following files should be committed:

- `package.json`
- `package-lock.json`
- Frontend source code
- Frontend configuration files

The following should not be committed:

- `node_modules/`
- `dist/`
- npm log files
- Local environment files

These generated files and directories are covered by the project's `.gitignore` configuration.

---

## 7. Frontend Development Responsibilities

The frontend team is responsible for:

- Implementing the React application.
- Developing UI components and layouts.
- Implementing application pages and navigation.
- Configuring frontend application logic.
- Integrating the frontend with the backend APIs.
- Managing frontend dependencies.
- Maintaining the frontend source code.

The Docker build infrastructure, shared volume, and Nginx integration are already part of the project environment.

Frontend developers should avoid modifying infrastructure configuration unless the change is discussed and agreed upon with the team.

---

## 8. Important Notes

1. Do not install Node.js or npm directly on the host machine for this project.
2. Do not commit `node_modules/` or compiled build output.
3. Always commit `package.json` and `package-lock.json` together when dependencies change.
4. The production frontend is served through Nginx.
5. The frontend builder and Nginx have separate responsibilities.
6. Keep frontend application code inside the `frontend/` directory.

---

**Happy coding!**