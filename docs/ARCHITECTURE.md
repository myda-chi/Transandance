# ft_transcendence: Architecture & Implementation Guide

> **What this file is:** the team's single source of truth for *what* we build, *how* the pieces fit, *who* builds what, and *in which order*.
> **What it is not:** the official `README.md` required by the subject (see section 16). That one is written progressively and in its own format.
> **Status:** v1.0, replaces `transandance_concept.md` (which assumed NestJS). Backend is now **Go + Gin**, frontend **React + TypeScript**.
> **Rule:** when we decide something, we update this file **the same day** and add a line to the Decision Log (section 15).

---

## Table of contents

1. [What we are building](#1-what-we-are-building)
2. [Team, roles and ownership](#2-team-roles-and-ownership)
3. [Requirements we must meet](#3-requirements-we-must-meet)
4. [Architecture overview](#4-architecture-overview)
5. [Repository structure](#5-repository-structure)
6. [Backend design (Go + Gin)](#6-backend-design-go--gin)
7. [Data model](#7-data-model)
8. [API contract and real-time protocol](#8-api-contract-and-real-time-protocol)
9. [Frontend design (React + TypeScript)](#9-frontend-design-react--typescript)
10. [Game rules](#10-game-rules)
11. [Infrastructure: Docker, Nginx, HTTPS, environment](#11-infrastructure-docker-nginx-https-environment)
12. [How we work: Git, reviews, board](#12-how-we-work-git-reviews-board)
13. [Implementation roadmap (who does what, in which order)](#13-implementation-roadmap-who-does-what-in-which-order)
14. [Module plan](#14-module-plan)
15. [Open decisions and decision log](#15-open-decisions-and-decision-log)
16. [Evaluation checklist](#16-evaluation-checklist)
17. [Glossary](#17-glossary)

---

## 1. What we are building

A **kid-friendly educational adventure game** in the browser. Something important has been lost from the world; the child explores **three islands** (Maths, Vocabulary, Culture), plays levels made of challenges, earns progress, unlocks new levels, and can **challenge a friend** to a live match.

### The users

| User | How they get in | What they do |
|---|---|---|
| **Parent** | Registers with email + password | Creates child accounts, manages Culture Island access, sees children's progress |
| **Child** | Username + password **created by the parent** (no email) | Plays solo levels, earns progress, challenges friends |
| **Admin** (internal) | Seeded account | Maintenance only. No admin UI in the first release |

### The two game modes

| | Solo mode | Friend challenge |
|---|---|---|
| Purpose | Learn and progress | Compete with a friend, live |
| Correct answer | Advances progress | Earns points |
| Answer speed | Not scored | Affects points |
| Result | Level completion, unlocks | Match score, winner, match history |
| Validation | Server-side | Server-side |

Both modes use **one shared quiz engine**. Only the *rules* differ (section 10).

### The core user journeys (what must work end to end)

1. **Parent onboarding:** register → log in → create a child (username + password) → set Culture Island access.
2. **Solo play:** child logs in → sees the island map → starts a level → answers questions → server validates → progress saved → next level unlocks.
3. **Friend challenge:** child invites a friend → friend accepts → both play the same questions live → server scores → winner shown → result saved in match history.
4. **Parent view:** parent sees each child's progress and recent matches.

### Non-negotiable product rules

- **The correct answer never reaches the browser** before the child answers.
- **The server decides** scores, progress, unlocks, and winners. The browser only displays them.
- **Culture Island restrictions are enforced by the backend**, not just hidden in the UI.
- **Child safety:** no open chat between children, minimal personal data, friendships controlled (decision D4).

---

## 2. Team, roles and ownership

### 2.1 Required roles (fill in names)

| Role | Name | Responsibilities |
|---|---|---|
| Product Owner (PO) | _____ | Vision, backlog, priorities, validates finished work, story and content decisions |
| Project Manager (PM) | _____ | Meetings, board, deadlines, blockers, keeps this file current |
| Tech Lead / Architect | _____ | Architecture, contracts, code quality, reviews critical changes |
| Developers | everyone | Build, test, review, document |

One person can hold two roles (we are four). All roles go in the official README.

### 2.2 Work tracks

| Track | Person | Owns |
|---|---|---|
| **F1: Frontend app** | _____ | React app shell, routing, auth screens, parent area, API client, i18n/RTL, Privacy & Terms pages |
| **F2: Frontend game** | _____ | Island map, level and quiz screens, animations and sounds, friend challenge screens, WebSocket client |
| **B1: Platform + Identity** | _____ | Docker Compose, Nginx, HTTPS, shared Go packages, Identity service (accounts, auth, parent-child, friends, culture access) |
| **B2: Data + Content + Game** | _____ | Migrations, seeds, Content service, Game service (quiz engine, scoring, progression, real-time matches) |

### 2.3 Ownership rules

- Every area has **one owner and one backup**. The backup reviews the owner's pull requests.
- **Each person also owns one feature end to end** (from database to screen), so everyone can explain a full slice at evaluation.
- **Cross-side reviews:** at least some backend PRs are reviewed by a frontend dev and vice versa.
- Shared, non-code work needs owners too:

| Work | Owner | Backup |
|---|---|---|
| Question content (Maths, Vocabulary, Culture) | _____ | _____ |
| Culture content review (accuracy, respectful tone) | _____ | _____ |
| Art, sound, asset licences (CREDITS) | _____ | _____ |
| Privacy Policy & Terms of Service text | _____ | _____ |
| Official README | PM | everyone |

---

## 3. Requirements we must meet

Missing any of these means **rejection**, regardless of modules.

- [ ] Frontend + backend + database.
- [ ] Git history with **commits from all four**, clear messages, visible work split.
- [ ] Starts with **one command** using Docker (`make up` → `docker compose up --build`).
- [ ] Works on the **latest Chrome**, with **zero console errors or warnings**.
- [ ] **Privacy Policy** and **Terms of Service** pages with real content, linked in the footer.
- [ ] **Multi-user:** many users at once, concurrent actions safe, no race conditions or corrupted data.
- [ ] Responsive, clear, accessible frontend, with a CSS framework (**Tailwind**).
- [ ] Secrets in a git-ignored **`.env`**; a committed **`.env.example`**.
- [ ] Database with a **clear schema and relations**.
- [ ] **Secure sign-up and login**, at least email + password with hashed and salted passwords.
- [ ] **Validation on both frontend and backend** for every form and input.
- [ ] **HTTPS** for every connection to the backend from outside.
- [ ] **14 module points** that are fully working and demonstrable (we target 16, section 14).
- [ ] Every member can **explain the project and their contributions**, and can make a **small live change**.
- [ ] AI may be used, but only for code we understand; **how we used AI goes in the README**.

---

## 4. Architecture overview

### 4.1 The big picture

```
                           ┌──────────────────────────────┐
                           │   Browser (Chrome)           │
                           │   React + TS + Tailwind      │
                           └──────────────┬───────────────┘
                                          │  HTTPS + WSS (only public entry)
                                          ▼
                           ┌──────────────────────────────┐
                           │   Nginx (reverse proxy)      │
                           │   TLS, routing, static files │
                           └──┬──────────┬─────────┬──────┘
             /api/identity/*  │          │         │  /api/game/*  and  /ws
                              │  /api/content/*    │
                              ▼          ▼         ▼
                   ┌────────────┐ ┌────────────┐ ┌────────────────────┐
                   │  Identity  │ │  Content   │ │       Game         │
                   │  (Go/Gin)  │ │  (Go/Gin)  │ │  (Go/Gin + WS)     │
                   │  :8081     │ │  :8082     │ │  :8083             │
                   └─────┬──────┘ └─────┬──────┘ └─────────┬──────────┘
                         │   internal HTTP calls (JSON)     │
                         │◀───────────────┼────────────────▶│
                         ▼                ▼                  ▼
                   ┌────────────────────────────────────────────────┐
                   │ PostgreSQL: one server, one schema per service │
                   │ identity.*        content.*         game.*     │
                   └────────────────────────────────────────────────┘
```

- **Only Nginx is public.** The services and the database live on the private Docker network.
- **Nginx acts as the gateway:** it terminates HTTPS, serves the built frontend, routes `/api/<service>/...` to the right service, and upgrades `/ws` to a WebSocket for the Game service.
- **Authentication** is checked inside each service by a shared Go middleware (section 6.5). The gateway is not the only line of defence.

### 4.2 The services

| Service | Responsibility | Owns (tables) | Must NOT do |
|---|---|---|---|
| **Identity** | Who users are; login; parent-child links; friendships; Culture access settings | `identity.*` | Store questions, scores, or match state |
| **Content** | Islands, levels, questions, answer options, translations; serves **safe** questions | `content.*` | Score answers, store progress |
| **Game** | Quiz sessions, answer validation, scoring, progression, unlocks, live matches (WebSocket), match history | `game.*` | Manage accounts or edit questions |

> Our earlier plan had six services (Gateway, Identity, Content, Game, Matchmaking, Parent/Activity). We merged them to three for a four-person team: **Nginx** is the gateway, **Matchmaking** lives inside Game (no network hop in the middle of a live match), and **Parent/Activity** features live in Identity (settings) and Game (progress queries). We can split later if there is time and a real reason.

### 4.3 How the services talk to each other

| Caller | Asks | Why |
|---|---|---|
| Game → Content | `GET /internal/questions?levelId=…` (with correct answers) | To run a session and validate answers |
| Game → Identity | `GET /internal/children/{id}/culture-access` | To refuse a Culture Island session if blocked |
| Game → Identity | `GET /internal/friendships/check?a=…&b=…` | To allow a challenge only between friends |
| Identity → Game | `GET /internal/children/{id}/progress` | For the parent progress view (or the frontend calls Game directly with a parent token; decision D7) |

Rules:

1. **A service only reads and writes its own schema.** Never query another service's tables. Ask that service over HTTP.
2. Internal endpoints live under `/internal/...`, are **not routed by Nginx**, and require a shared secret header (`X-Internal-Token`, from `.env`).
3. No database transactions across services. Use clear steps, idempotent requests, and explicit statuses.
4. **No Go package imports between services:** `internal/game` never imports `internal/identity`. Shared code lives only in `internal/platform`.

### 4.4 One request, step by step (example: a child answers a question)

```
1. Browser  POST https://localhost/api/game/sessions/42/answers  {questionId, optionId}
2. Nginx    routes /api/game/* → game:8083
3. Game     auth middleware checks the JWT → child #7
4. Game     checks session 42 belongs to child #7 and is still active
5. Game     looks up the correct option (cached from Content when the session started)
6. Game     saves the answer, updates score/progress in ONE database transaction
7. Game     responds {correct: true, progress: {...}, nextQuestion: {...safe payload...}}
8. Browser  plays the success animation and shows the next question
```

---

## 5. Repository structure

One repository for everything. This is how it should look:

```
transcendence/
├── Makefile                     # make up / down / logs / reset / test
├── docker-compose.yml
├── .env.example                 # every variable, fake values (committed)
├── .gitignore                   # includes .env, node_modules, build output
├── README.md                    # official README (written progressively)
│
├── docs/
│   ├── ARCHITECTURE.md          # this file
│   ├── api/
│   │   └── openapi.yaml         # THE API contract (source of truth for both sides)
│   └── decisions/               # one short file per important decision
│
├── nginx/
│   ├── nginx.conf               # TLS, routes, WebSocket upgrade, security headers
│   └── certs/                   # generated dev certificates (git-ignored)
│
├── backend/                     # ONE Go module (one go.mod)
│   ├── go.mod
│   ├── cmd/
│   │   ├── identity/main.go     # starts the Identity service
│   │   ├── content/main.go      # starts the Content service
│   │   └── game/main.go         # starts the Game service
│   ├── internal/
│   │   ├── platform/            # SHARED by all services
│   │   │   ├── config/          # loads .env into a Config struct
│   │   │   ├── database/        # opens the GORM connection
│   │   │   ├── logger/
│   │   │   ├── apierror/        # the one JSON error format
│   │   │   ├── auth/            # JWT creation/verification + Gin middleware
│   │   │   └── internalclient/  # HTTP client for /internal calls (adds the secret header)
│   │   ├── identity/            # Identity's own code (only used by cmd/identity)
│   │   ├── content/             # Content's own code
│   │   └── game/                # Game's own code (incl. websocket hub)
│   ├── migrations/
│   │   ├── identity/            # 000001_create_users.up.sql / .down.sql ...
│   │   ├── content/
│   │   └── game/
│   ├── seeds/                   # islands, levels, questions (JSON) + loader
│   └── Dockerfile               # multi-stage; builds one service via a build arg
│
└── frontend/
    ├── package.json
    ├── vite.config.ts
    ├── tailwind.config.ts
    ├── Dockerfile               # builds static files for Nginx
    └── src/
        ├── app/                 # router, providers, layout (header, footer)
        ├── pages/               # one folder per screen (section 9.2)
        ├── features/            # auth, parent, map, quiz, challenge
        ├── components/          # reusable UI (Button, Card, Modal, ...)
        ├── game/                # animations, sounds, (Phaser scenes if used)
        ├── api/                 # generated types + typed API client + ws client
        ├── i18n/                # en.json, fr.json, ar.json
        └── styles/
```

**How the backend layout works:** there is one Go project (`go.mod`), but **three programs**. `go build ./cmd/identity` produces the Identity program, and so on. Docker runs each program in its own container. In the code they share the toolbox in `internal/platform`; at runtime they are separate services that talk over the network.

---

## 6. Backend design (Go + Gin)

### 6.1 Libraries (agree once, use everywhere)

| Need | Library | Notes |
|---|---|---|
| HTTP framework | **Gin** (`github.com/gin-gonic/gin`) | Routing, middleware, JSON binding |
| ORM | **GORM** (`gorm.io/gorm` + postgres driver) | Counts for the ORM module |
| Migrations | **golang-migrate** | Versioned `.up.sql` / `.down.sql` files, reviewed in PRs |
| Validation | Gin `binding` tags (go-playground/validator) | `binding:"required,min=3,max=20"` |
| Passwords | `golang.org/x/crypto/bcrypt` (or argon2) | Never store or log plain passwords |
| Tokens | `github.com/golang-jwt/jwt/v5` | Access token + refresh token |
| WebSockets | `github.com/gorilla/websocket` (or `coder/websocket`) | Game service only |
| Config | environment variables (+ a small loader) | Values come from `.env` via Docker Compose |
| Tests | Go `testing` + `httptest`; `go test -race ./...` | Race detector is mandatory before merging |

Check each library's current version and docs when you add it.

### 6.2 Inside one service: three layers

Every service is organised the same way, so anyone can find anything:

```
internal/identity/
├── routes.go        # registers the Gin routes for this service
├── handler.go       # HTTP layer: read request, validate, call service, write JSON
├── service.go       # business rules (e.g. "a parent may only edit their own children")
├── repository.go    # database access with GORM (the only layer that touches the DB)
├── models.go        # GORM structs = tables
└── dto.go           # request/response structs with validation tags
```

**Rule:** handlers never talk to the database directly; repositories never contain business rules. This keeps code testable and easy to explain.

What a `main.go` looks like (shape, not final code):

```go
func main() {
    cfg := config.Load()                       // reads env vars
    db := database.Connect(cfg.DatabaseURL)    // GORM connection
    r := gin.New()
    r.Use(gin.Recovery(), logger.Middleware())
    r.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })
    identity.RegisterRoutes(r, db, cfg)        // this service's routes
    r.Run(":" + cfg.Port)
}
```

### 6.3 One error format everywhere

Every error from every service looks like this:

```json
{ "error": { "code": "VALIDATION_FAILED", "message": "username is too short", "details": [ { "field": "username", "rule": "min" } ] } }
```

Common codes: `VALIDATION_FAILED` (400), `UNAUTHENTICATED` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `CONFLICT` (409), `RATE_LIMITED` (429), `INTERNAL` (500). The frontend translates `code` into a friendly message in the user's language. Never send stack traces or SQL errors to the browser.

### 6.4 Authentication flow

| Step | What happens |
|---|---|
| Parent registers | `POST /api/identity/auth/register` with email + password → password hashed with bcrypt → account created |
| Parent logs in | `POST /api/identity/auth/login` → access token (short, ~15 min) + refresh token (longer, stored hashed in DB) |
| Parent creates child | `POST /api/identity/children` with username + password → child user created + parent-child link |
| Child logs in | `POST /api/identity/auth/child-login` with username + password → tokens with role `CHILD` |
| Refresh | `POST /api/identity/auth/refresh` → new access token; refresh token rotated |
| Logout | `POST /api/identity/auth/logout` → refresh token revoked |

**Token contents (JWT claims):** `sub` (user id), `role` (`PARENT`/`CHILD`/`ADMIN`), `exp`. Nothing private.

**Where tokens live in the browser (decision D6):** recommended is **httpOnly, Secure, SameSite cookies** (JavaScript cannot steal them; we add CSRF protection), or an access token in memory with the refresh token in an httpOnly cookie. Never `localStorage` for tokens.

### 6.5 Authorization (who may do what)

`internal/platform/auth` provides a Gin middleware that verifies the JWT and puts the user id and role on the request. Each **service** then checks **ownership**, not just role.

| Action | Child | Parent | Admin |
|---|---|---|---|
| Play solo, challenge friends, see own progress | ✓ (self) | | |
| Create / edit / delete child accounts | | ✓ (own children) | ✓ |
| Reset a child's password | | ✓ (own children) | ✓ |
| Set Culture Island access | | ✓ (own children) | ✓ |
| See a child's progress and match history | own | ✓ (own children) | ✓ |
| Send / accept friend requests | ✓ (rules in D4) | approves (if D4 says so) | |

Every protected endpoint has a test for **"wrong user gets 403"**.

### 6.6 Database rules

- **One PostgreSQL server, three schemas:** `identity`, `content`, `game`. Each service connects with its own DB user that can only access its own schema (strongly recommended; it *proves* the ownership rule).
- **Migrations are SQL files** run automatically at startup (or by a `migrate` container) and committed to Git. Never change the schema by hand.
- **Foreign keys inside a schema; plain IDs across schemas.** For example, `game.quiz_sessions.player_user_id` stores the user's ID, but there is no foreign key to `identity.users`, because that table belongs to another service.
- **Transactions** wrap every multi-step write inside a service (e.g. save answer + update score).
- **Concurrency:** unique constraints stop double submissions (e.g. one answer per question per session per player). Live match state in memory is protected with a mutex or owned by one goroutine. Run `go test -race`.

### 6.7 Seeds (content as data)

Questions are written as **JSON files** in `backend/seeds/`, reviewed in pull requests, and loaded by a seed command. Adding content should not require changing Go code.

```json
{
  "island": "maths",
  "level": { "slug": "maths-1", "order": 1, "difficulty": 1 },
  "questions": [
    {
      "type": "MULTIPLE_CHOICE",
      "prompt": { "en": "What is 5 + 3?", "fr": "Combien font 5 + 3 ?", "ar": "كم يساوي 5 + 3؟" },
      "options": [
        { "text": { "en": "6", "fr": "6", "ar": "6" }, "correct": false },
        { "text": { "en": "8", "fr": "8", "ar": "8" }, "correct": true },
        { "text": { "en": "9", "fr": "9", "ar": "9" }, "correct": false }
      ]
    }
  ]
}
```

Have a native speaker check every Arabic and French translation.

---

## 7. Data model

A **starting** schema. Field names and types are finalised in the migrations; update this section when they change.

### 7.1 Diagram

```mermaid
erDiagram
    USERS ||--o{ PARENT_CHILD : "parent"
    USERS ||--o{ PARENT_CHILD : "child"
    USERS ||--o{ FRIENDSHIPS : "requester / addressee"
    USERS ||--o| CULTURE_ACCESS : "child setting"
    USERS ||--o{ REFRESH_TOKENS : has
    ISLANDS ||--o{ LEVELS : contains
    LEVELS ||--o{ QUESTIONS : contains
    QUESTIONS ||--o{ ANSWER_OPTIONS : has
    QUESTIONS ||--o{ QUESTION_TRANSLATIONS : "translated as"
    ANSWER_OPTIONS ||--o{ OPTION_TRANSLATIONS : "translated as"
    QUIZ_SESSIONS ||--o{ SESSION_PLAYERS : includes
    QUIZ_SESSIONS ||--o{ ANSWER_SUBMISSIONS : records
    QUIZ_SESSIONS ||--o| MATCHES : "is played as"
    CHALLENGES ||--o| MATCHES : "becomes"
```

(Renders on GitHub and in VS Code with a Mermaid extension. Lines between schemas, such as users to quiz sessions, are IDs only, not foreign keys.)

### 7.2 Tables by owner

**Identity (`identity.*`)**

| Table | Key columns | Constraints / notes |
|---|---|---|
| `users` | id (UUID), role, email (nullable), username (nullable), password_hash, display_name, status, created_at, updated_at | Parents: email unique, required. Children: username unique, required, no email |
| `parent_child` | id, parent_user_id → users, child_user_id → users, created_at | Unique (parent, child). If one parent per child (D2): unique (child) too |
| `friendships` | id, requester_id, addressee_id, status (`PENDING`/`ACCEPTED`/`DECLINED`), created_at, updated_at | One row per pair (store the smaller ID first, unique pair); no self-friendship |
| `culture_access` | child_user_id (PK) → users, allowed (bool), updated_by, updated_at | Whole-island on/off to start |
| `refresh_tokens` | id, user_id, token_hash, expires_at, revoked_at | Store the hash, not the token |

**Content (`content.*`)**

| Table | Key columns | Notes |
|---|---|---|
| `islands` | id, slug (`maths`/`vocabulary`/`culture`), display_order | Names come from translation keys |
| `levels` | id, island_id → islands, slug, display_order, difficulty | Unique (island, display_order) |
| `questions` | id, level_id → levels, type, difficulty, is_active | Language-independent part |
| `question_translations` | question_id, locale, prompt | Unique (question, locale) |
| `answer_options` | id, question_id → questions, display_order, is_correct | **is_correct is never sent to the browser** |
| `option_translations` | option_id, locale, text | Unique (option, locale) |

**Game (`game.*`)**

| Table | Key columns | Notes |
|---|---|---|
| `quiz_sessions` | id, mode (`SOLO`/`CHALLENGE`), island_id, level_id, status (`ACTIVE`/`COMPLETED`/`ABANDONED`), started_at, completed_at | One engine for both modes |
| `session_players` | session_id → quiz_sessions, player_user_id, score, result (`WIN`/`LOSS`/`DRAW`/null) | Solo = 1 row, challenge = 2 rows |
| `answer_submissions` | id, session_id, player_user_id, question_id, selected_option_id, is_correct, response_time_ms, answered_at | Unique (session, player, question): blocks double answers |
| `level_progress` | player_user_id, level_id, status (`LOCKED`/`UNLOCKED`/`COMPLETED`), best_score, attempt_count, completed_at | The authoritative progress |
| `challenges` | id, challenger_id, opponent_id, level_id, status (`PENDING`/`ACCEPTED`/`DECLINED`/`EXPIRED`), created_at, expires_at | Invitations |
| `matches` | id, challenge_id → challenges, session_id → quiz_sessions, status, started_at, completed_at | The durable record of a live match; scores live in `session_players` (stored once) |

---

## 8. API contract and real-time protocol

### 8.1 Contract first

`docs/api/openapi.yaml` is **the** contract. Workflow:

1. A change to an endpoint starts as a PR that edits `openapi.yaml`. Both a frontend and a backend dev review it.
2. The frontend generates TypeScript types from it (`openapi-typescript`), so frontend and backend can't silently disagree.
3. The backend implements it (optionally generating Go types with `oapi-codegen`).
4. Until the backend is ready, the frontend uses **mock data** that follows the contract, so nobody waits.

### 8.2 Conventions

- Public paths: `/api/<service>/...`; internal paths: `/internal/...` (never routed by Nginx).
- JSON only, `camelCase` fields in JSON, plural nouns (`/children`, `/levels`).
- IDs are UUIDs; dates are ISO 8601 UTC strings.
- Lists are paginated (`?page=1&pageSize=20`) where they can grow.
- The error format from section 6.3, always.

### 8.3 First endpoints (v0)

| Method & path | Service | Who | Purpose |
|---|---|---|---|
| `POST /api/identity/auth/register` | Identity | public | Parent sign-up |
| `POST /api/identity/auth/login` | Identity | public | Parent login |
| `POST /api/identity/auth/child-login` | Identity | public | Child login |
| `POST /api/identity/auth/refresh` · `/logout` | Identity | logged in | Sessions |
| `GET /api/identity/me` | Identity | logged in | Current user |
| `GET/POST /api/identity/children` | Identity | parent | List / create children |
| `PATCH/DELETE /api/identity/children/{id}` | Identity | parent (own) | Edit / delete child |
| `PUT /api/identity/children/{id}/culture-access` | Identity | parent (own) | Set Culture access |
| `GET/POST /api/identity/friends` · `PATCH /friends/{id}` | Identity | child | Friends and requests |
| `GET /api/content/islands` | Content | logged in | Islands + levels (no questions) |
| `POST /api/game/sessions` | Game | child | Start a solo session `{levelId}` |
| `GET /api/game/sessions/{id}/question` | Game | child (own) | Next question, **safe payload** |
| `POST /api/game/sessions/{id}/answers` | Game | child (own) | Submit an answer |
| `GET /api/game/progress` | Game | child | Own progress, unlocked levels |
| `GET /api/game/children/{id}/progress` | Game | parent (own) | Parent view |
| `GET /api/game/matches` | Game | child / parent | Match history |
| `POST /api/game/challenges` · `PATCH /challenges/{id}` | Game | child | Invite / accept / decline |

Safe question payload (what the browser receives):

```json
{ "questionId": "q-123", "prompt": "What is 5 + 3?",
  "options": [ {"id": "a", "text": "6"}, {"id": "b", "text": "8"}, {"id": "c", "text": "9"} ] }
```

### 8.4 WebSocket protocol (friend challenges)

Connection: `wss://localhost/ws` (Nginx → Game). The client authenticates during the connection (cookie, or a short-lived ticket from `POST /api/game/ws-ticket`). Every message is JSON: `{ "type": "...", "payload": { ... } }`.

| Type | Direction | Payload | When |
|---|---|---|---|
| `challenge.received` | server → client | challengeId, from | A friend invites you |
| `match.join` | client → server | matchId | Player enters the match screen |
| `match.ready` | server → clients | players | Both connected |
| `match.question` | server → clients | index, safe question, deadline | Each round |
| `match.answer` | client → server | questionId, optionId | Player answers |
| `match.score` | server → clients | scores | After each round |
| `match.opponent_disconnected` | server → client | graceSeconds | Opponent dropped |
| `match.resumed` | server → clients | full current state | Reconnected within grace period |
| `match.end` | server → clients | final scores, winner, reason | Finished, forfeit, or timeout |
| `error` | server → client | code, message | Invalid message |
| `ping` / `pong` | both | — | Heartbeat (detect dead connections) |

**Match lifecycle (state machine):**

```
PENDING ──accept──▶ WAITING_FOR_PLAYERS ──both joined──▶ IN_PROGRESS ──last round──▶ COMPLETED
   │                        │                                 │
 decline/expire        timeout                      player gone > grace period
   ▼                        ▼                                 ▼
DECLINED / EXPIRED      CANCELLED                     COMPLETED (forfeit)
```

The **server** measures response times and decides points and the winner. A client that sends a score is ignored.

---

## 9. Frontend design (React + TypeScript)

### 9.1 Stack

| Need | Choice |
|---|---|
| Build / dev server | Vite + React + TypeScript |
| Styling | Tailwind CSS (with logical properties for RTL: `ms-`, `me-`, `ps-`, `pe-`) |
| Routing | React Router |
| Server data | TanStack Query (caching, loading and error states) |
| Forms + validation | React Hook Form + Zod (same rules as the backend) |
| i18n | i18next / react-i18next (en, fr, ar) |
| Real-time | the browser's native `WebSocket`, wrapped in `src/api/ws.ts` |
| Game visuals | CSS/Framer-style animations; Phaser only if a mini-game truly needs a canvas |
| Types | generated from `openapi.yaml` |

### 9.2 Screens

| # | Screen | Who | Notes |
|---|---|---|---|
| 1 | Landing | public | What the game is, login buttons |
| 2 | Parent register / login | public | Validated forms |
| 3 | Child login | public | Big, simple; username + password |
| 4 | Parent dashboard | parent | Children list, add child, progress summary |
| 5 | Child settings | parent | Reset password, Culture access toggle, delete |
| 6 | Island map | child | Three islands, locked/unlocked levels, avatar |
| 7 | Level / quiz | child | Question, options, feedback animation, progress bar |
| 8 | Level complete | child | Stars or score, next level unlocked |
| 9 | Friends | child | Friend list, requests (per D4), challenge button |
| 10 | Challenge lobby + live match | child | Waiting, countdown, live scores, result |
| 11 | Match history | child / parent | Past matches |
| 12 | Privacy Policy, Terms of Service | everyone | Footer links on every page |
| 13 | 404 / error page | everyone | Friendly, translated |

### 9.3 How it should look and feel

- **Playful but calm:** bright island colours on soft backgrounds, rounded shapes, large readable fonts, big buttons (easy for small hands and tablets).
- **Feedback for every action:** a gentle animation and sound for correct answers; an encouraging message and a retry for wrong ones. Never a harsh "FAIL" screen.
- **Little text, more icons,** always paired with words for clarity.
- **Responsive:** phone, tablet, and desktop. Test all three.
- **Accessible:** keyboard navigation in menus and forms, visible focus, labels on inputs, alt text on images, enough colour contrast, a mute button, respect for `prefers-reduced-motion`.
- **RTL:** when Arabic is selected, the whole layout mirrors (`<html dir="rtl">`), not just the text.
- **A small set of reusable components** (`Button`, `Card`, `Modal`, `Input`, `IslandCard`, `QuestionCard`, `ProgressBar`, `Toast`, `Avatar`, `LanguageSwitcher`). Agree on colours, fonts, and spacing in Week 1 (a one-page style guide).

### 9.4 Frontend rules

- **Every** user-facing string comes from `src/i18n/*.json`; nothing hardcoded.
- **No console errors or warnings,** ever. Treat them as bugs (missing `key` props, failed asset loads, unhandled promise rejections).
- All API calls go through `src/api/` (one place for base URL, credentials, error handling).
- The browser never decides scores, unlocks, or winners; it displays what the server returns.
- Forms validate on the client for a friendly experience, and the server validates again for security.

---

## 10. Game rules

These need team decisions (section 15). Defaults to start with:

### 10.1 Solo mode

- A level has **N questions** (start with 5).
- A level is **completed** when the child gets at least **M correct** (start with 3 of 5).
- Completing a level **unlocks the next level** on the same island. The first level of each island is unlocked from the start.
- Wrong answers: show feedback, move on. The child can replay a level any time; `best_score` is kept.
- **Culture Island:** if the parent has disabled it, the island is shown as unavailable and the **backend refuses** to start a session there.

### 10.2 Friend challenge

- Only between **friends** (D4), on a level both can access.
- Both players get the **same questions in the same order**.
- Each round has a time limit (start with 15 seconds).
- **Points:** 0 for a wrong answer; for a correct answer, for example `100 + bonus for speed` measured **by the server** (formula decided by the team, D8).
- **Ties:** a draw (or a tie-break rule decided in D8).
- **Disconnect:** the opponent sees "reconnecting", there is a grace period (start with 20 seconds), then a forfeit win.
- The result is saved once, by the Game service, and appears in both players' match history.

---

## 11. Infrastructure: Docker, Nginx, HTTPS, environment

### 11.1 Containers

| Container | Image / build | Port (internal) | Public? |
|---|---|---|---|
| `nginx` | nginx + our config + built frontend files | 443 (and 80 → redirect) | **Yes, the only one** |
| `identity` | `backend/Dockerfile`, `SERVICE=identity` | 8081 | No |
| `content` | `backend/Dockerfile`, `SERVICE=content` | 8082 | No |
| `game` | `backend/Dockerfile`, `SERVICE=game` | 8083 | No |
| `postgres` | postgres (pinned version) + named volume | 5432 | No |
| `migrate` | golang-migrate, runs once then exits | — | No |

- **One command:** `make up` runs `docker compose up --build`. It must work on a **fresh clone** after `cp .env.example .env`.
- An init SQL script (mounted into `postgres`) creates the three schemas and one database user per service, each allowed only its own schema.
- Services wait for Postgres to be healthy (Compose `healthcheck` + `depends_on: condition: service_healthy`).
- The backend `Dockerfile` is **multi-stage**: stage 1 compiles the Go program, stage 2 copies only the binary into a tiny image.
- Avatar uploads (standard user management module) are stored in a named volume owned by Identity, with type and size validation.

### 11.2 Nginx essentials

```nginx
# HTTPS only; HTTP redirects to HTTPS
location /                { root /usr/share/nginx/html; try_files $uri /index.html; }  # React app
location /api/identity/   { proxy_pass http://identity:8081; }
location /api/content/    { proxy_pass http://content:8082; }
location /api/game/       { proxy_pass http://game:8083; }
location /ws {
    proxy_pass http://game:8083;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_read_timeout 3600s;   # keep long-lived game connections open
}
# /internal/* is deliberately NOT routed: it stays private to the Docker network.
```

With `proxy_pass` written without a trailing path, the full URL is forwarded, so each Gin service groups its routes under its prefix (`r.Group("/api/identity")`). Add security headers (HSTS, `X-Content-Type-Options`, a Content-Security-Policy) once the app works.

### 11.3 HTTPS in development

A script (`make certs`) generates a self-signed certificate with `openssl` (or `mkcert` for a locally trusted one) into `nginx/certs/`, which is git-ignored. The app is reached at `https://localhost`. **Get everything working over plain HTTP first, then switch on TLS as a separate step.**

### 11.4 Environment variables (`.env.example`)

```dotenv
# Database
POSTGRES_USER=transcendence
POSTGRES_PASSWORD=change_me
POSTGRES_DB=transcendence
IDENTITY_DB_URL=postgres://identity_svc:change_me@postgres:5432/transcendence?sslmode=disable&search_path=identity
CONTENT_DB_URL=postgres://content_svc:change_me@postgres:5432/transcendence?sslmode=disable&search_path=content
GAME_DB_URL=postgres://game_svc:change_me@postgres:5432/transcendence?sslmode=disable&search_path=game

# Auth
JWT_SECRET=change_me_to_a_long_random_string
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=168h

# Service-to-service
INTERNAL_TOKEN=change_me_too
CONTENT_INTERNAL_URL=http://content:8082
IDENTITY_INTERNAL_URL=http://identity:8081

# App
APP_ORIGIN=https://localhost
```

The real `.env` is **never committed**. If a secret is ever pushed by mistake, change it immediately.

### 11.5 Makefile targets

| Target | Does |
|---|---|
| `make up` | Build and start everything |
| `make down` | Stop everything |
| `make logs` | Follow logs from all containers |
| `make reset` | Stop, delete the database volume, start fresh (migrations + seeds) |
| `make seed` | Load seed content |
| `make test` | Backend `go test -race ./...` + frontend tests |
| `make certs` | Generate development TLS certificates |

---

## 12. How we work: Git, reviews, board

### 12.1 Git

- `main` is protected and **always runs**. No direct pushes.
- Branches: `feat/<area>-<short-name>`, `fix/...`, `docs/...`, `chore/...`. Short-lived: merge within a few days.
- **Commit messages:** Conventional Commits, e.g. `feat(identity): add child account creation`, `fix(game): reject duplicate answers`. The subject grades our history, so everyone commits regularly, with clear messages.
- Never commit `.env`, certificates, `node_modules`, build output, or large binary files.

### 12.2 Pull requests

- One purpose per PR; a short description; linked issue; screenshots for UI changes.
- **At least one review** from someone other than the author (the area's backup by default).
- Checks before merge: builds, tests pass, `go test -race` clean, lint clean, no console warnings for UI changes.
- If an endpoint changes, the `openapi.yaml` change is in the same PR (or merged first).

### 12.3 Board (GitHub Projects or Trello)

- Columns: **Backlog → Ready → In progress → In review → Done**.
- Card titles: `[AREA] verb + object`, e.g. `[IDENTITY] Create child account`, `[FRONT] Island map screen`.
- Labels: `frontend`, `backend`, `infra`, `content`, `docs`, `bug`, and one per module (`module:websockets`).
- A card is small enough to finish in **1-3 days**. Larger? Split it.

### 12.4 Meetings

- **Weekly planning (45 min):** what got done, what's next, blockers, decisions → update this file.
- **Mid-week check-in (15 min, chat is fine):** anyone stuck?
- **End of each phase:** demo from a fresh clone.

### 12.5 Definition of Done

A task is done only when:

- [ ] It works with `make up` from a fresh clone.
- [ ] Inputs are validated on both sides (if any).
- [ ] Tests exist for the main path and the main failure (e.g. wrong user → 403).
- [ ] No browser console errors or warnings.
- [ ] Reviewed and merged.
- [ ] The contract and this file are updated if something changed.
- [ ] Someone besides the author can explain it.

### 12.6 Using AI (subject rule)

- AI is fine for explanations, boilerplate, and ideas. **Never merge code nobody on the team can explain.**
- Walk through AI-generated code with a teammate before merging, and test it.
- Keep a running note of where and how AI was used. The README's Resources section requires it.

---

## 13. Implementation roadmap (who does what, in which order)

The **order** matters more than the dates. Adjust the week numbers to our real deadline. The big rule: **one working path end to end first, then widen it.**

### Phase 0: Decide and learn (week 1)

| Task | Owner | Done when |
|---|---|---|
| Fill names in section 2; agree roles | All | Table filled |
| Settle decisions D1-D5 (section 15) | All, PO leads | Logged in 15.2 |
| Ask staff: does Gin count as a backend framework? Does our friend-challenge design count for the game modules? Do our friend rules satisfy standard user management? | PM | Answers logged |
| Backend learning: Tour of Go, a Gin JSON route, GORM + Postgres in Docker | B1, B2 | Each has a throwaway mini-app running |
| Frontend learning: React + TS + Tailwind basics, React Router, fetch from an API | F1, F2 | Each has a throwaway mini-app running |
| Board set up with Phase 1-2 cards | PM | Board ready |
| One-page style guide (colours, fonts, spacing, button style) | F1 + F2 | Agreed and committed |

### Phase 1: Walking skeleton (weeks 2-3)

| Task | Owner | Done when |
|---|---|---|
| Repo structure (section 5), `.gitignore`, `.env.example`, Makefile | B1 | Committed |
| Docker Compose: Postgres, 3 services (health endpoint only), Nginx | B1 | `make up` starts all containers |
| Nginx routing + WebSocket echo through `/ws` | B1 | Echo works from the browser |
| HTTPS with dev certificates | B1 | `https://localhost` works, no mixed-content warnings |
| `internal/platform`: config, database, logger, apierror | B1 (B2 reviews) | Used by all three services |
| Migrations setup + schema v0 for all three schemas | B2 (B1 reviews) | `make reset` rebuilds the DB |
| `openapi.yaml` v0 (endpoints in 8.3, first half) | B1 + B2 + F1 | Merged; frontend types generate |
| Vite React TS app, Tailwind, router, layout, footer links | F1 | App served by Nginx |
| API client + mock layer using generated types | F1 | Screens can run on mocks |
| Island map screen prototype (static data) | F2 | Looks like the style guide |
| **Phase exit:** fresh clone → `make up` → `https://localhost` shows the app, which displays data fetched from a real service | All | Demo done |

### Phase 2: Accounts (weeks 3-5)

| Task | Owner | Done when |
|---|---|---|
| Parent register / login / refresh / logout, bcrypt, JWT, rate limit on login | B1 | Tests: success, bad password, duplicate email |
| Auth middleware in `internal/platform/auth` | B1 | Used by Content and Game |
| Child accounts (create, list, edit, delete, reset password) + parent-child link | B1 | Tests: parent A cannot touch parent B's child |
| Child login | B1 | Tests pass |
| Parent register/login screens with validation | F1 | Works against the real API |
| Parent dashboard + create-child form + child login screen | F1 | End to end with the real API |
| Protected routes by role in the frontend | F1 | Child can't open parent pages and vice versa |
| Privacy Policy and Terms (first real draft) | PO | Linked in footer |
| **Phase exit:** a parent signs up, creates a child; the child logs in and lands on the map | All | Demo done |

### Phase 3: Solo play, the first real vertical slice (weeks 4-7)

| Task | Owner | Done when |
|---|---|---|
| Seed format + loader; Maths island, 2-3 levels, 5 questions each (en first) | B2 | `make seed` loads them |
| Content API: islands + levels; internal questions endpoint with answers | B2 | Public API never exposes `is_correct` (test) |
| Game: start session, get next question (safe), submit answer, validate | B2 | Tests incl. duplicate and late answers rejected |
| Solo rules: level completion, unlock next level, `level_progress` | B2 | Test: client cannot fake progress |
| Culture access setting (Identity) + check in Game | B1 + B2 | Test: blocked child gets 403 |
| Map with real locked/unlocked levels | F2 | From the API |
| Quiz screen: question, options, feedback animation and sound, progress bar | F2 | Plays a full level |
| Level-complete screen | F2 | Shows result, next level unlocked |
| Culture toggle in child settings | F1 | Works end to end |
| **Phase exit (first milestone):** child logs in → plays a Maths level → server validates every answer → progress saved → next level unlocked; reload keeps progress | All | Demo done |

### Phase 4: Friends and live challenges (weeks 7-10)

| Task | Owner | Done when |
|---|---|---|
| Friendships (request, accept, decline, list) per D4 + online status | B1 | Tests incl. no duplicates, no self-friendship |
| WebSocket hub in Game: auth, connections, heartbeat | B2 | Two browsers connected, dead connections detected |
| Challenges: invite, accept, decline, expire | B2 | Tests |
| Match engine: same questions, rounds, server timing, scoring, end, persistence | B2 | Two simultaneous matches don't interfere; `go test -race` clean |
| Disconnect + reconnect with grace period, forfeit | B2 | Demonstrable by closing a tab |
| Friends screen + challenge button + incoming challenge popup | F1 | Works with the real API |
| Lobby, live match screen, countdown, scores, result | F2 | Full match playable |
| Reconnecting UI | F2 | Shows state and recovers |
| **Phase exit:** two children on two computers play a full match; one disconnects and reconnects; the result appears in both match histories | All | Demo done |

### Phase 5: Complete the modules (weeks 9-12)

| Task | Owner | Done when |
|---|---|---|
| Profile page, profile edit, avatar upload with default avatar | B1 + F1 | Standard user management fully demonstrable |
| Match history + statistics (wins, losses, level progress, leaderboard among friends) | B2 + F1 | Game statistics module demonstrable |
| i18n: all strings in en/fr/ar; language switcher; translated content | F1 (+ content owners) | Switching changes everything visible |
| RTL: full layout mirroring for Arabic | F1 + F2 | Every screen checked in Arabic |
| Parent progress view | F1 + B2 | Parent sees each child's progress and matches |
| Second and third islands (Vocabulary, Culture): mostly seed data | Content owners + B2 | Playable |

### Phase 6: Hardening and evaluation prep (final 2 weeks)

| Task | Owner | Done when |
|---|---|---|
| Feature freeze; bug fixing | All | No open critical bugs |
| Console clean on every screen; responsive pass; accessibility pass | F1 + F2 | Checked in Chrome |
| Security pass (section 16), `go test -race`, dependency audit | B1 + B2 | Checklist complete |
| Final Privacy Policy and Terms | PO | Reviewed by the team |
| Official README complete | PM + all | All required sections |
| Demo script per module; full rehearsal from a fresh clone; practise small live changes | All | Rehearsal done twice |

---

## 14. Module plan

We need **14 points**; we target **16** so one failed module does not sink us. A module counts only if it is **complete and demonstrated live**.

### 14.1 Planned modules (16 points)

| Module (subject category) | Type | Pts | How we satisfy it | Owners | Risk |
|---|---|---|---|---|---|
| Use a framework for frontend and backend (Web) | Major | 2 | React + Gin | All | Low, **if staff confirm Gin counts** |
| Real-time features with WebSockets (Web) | Major | 2 | Live challenges, online status, graceful disconnects, broadcasting to match rooms | B2 + F2 | Medium |
| Standard user management (User Mgmt) | Major | 2 | Profile edit, avatar upload with default, friends + online status, profile page | B1 + F1 | Medium (child-safety design D4) |
| Complete web-based game, users play against each other (Gaming) | Major | 2 | Friend challenge: live match, clear rules, win/loss | B2 + F2 | Medium |
| Remote players (Gaming) | Major | 2 | Two players on separate computers, latency and reconnection handled | B2 + F2 | Medium |
| Backend as microservices (DevOps) | Major | 2 | Identity, Content, Game: separate programs and containers, single responsibility, REST between them | B1 + B2 | Medium-high |
| Use an ORM (Web) | Minor | 1 | GORM | B1 + B2 | Low |
| Multiple languages, at least 3 (Accessibility) | Minor | 1 | English, French, Arabic + switcher | F1 | Medium (translation work) |
| Right-to-left support (Accessibility) | Minor | 1 | Arabic with full layout mirroring | F1 + F2 | Medium |
| Game statistics and match history (User Mgmt) | Minor | 1 | Wins/losses, match history, progression, leaderboard among friends | B2 + F1 | Low |
| **Total** | | **16** | | | |

### 14.2 Backups if a module is at risk

| Module | Pts | Note |
|---|---|---|
| Advanced permissions system | 2 | Roles parent/child/admin with CRUD on users and role-based views; needs an admin area |
| Gamification (3+ of: achievements, badges, leaderboards, XP, daily challenges, rewards) | 1 | Natural for a kids' game |
| GDPR compliance features | 1 | Parent can export and delete data; needs confirmation emails |
| Notification system | 1 | Reuses the WebSocket work |
| Custom design system (10+ reusable components) | 1 | We are building the components anyway (section 9.3) |

### 14.3 Things to remember

- **Not claimed on purpose:** "Allow users to interact with other users" (requires **chat**). Open chat between children is a safety risk.
- **Dependencies:** remote players and game statistics need a working game first.
- For each module, write a **demo script** before the evaluation:

```
Module: ____________  |  Owner: ______  |  Backup: ______
Setup (accounts/data needed):
Steps to show:
Expected result:
Edge case to show (disconnect, invalid input, wrong user):
Code to be ready to explain:
```

---

## 15. Open decisions and decision log

### 15.1 Open decisions

| # | Decision | Default until decided | Blocks | Decide by |
|---|---|---|---|---|
| D1 | Target age band | 7-10 | Content, UI tone | Phase 0 |
| D2 | One parent per child, or several guardians? | One (unique child link) | `parent_child` constraint | Phase 0 |
| D3 | The story: what was lost? | "The lost light of knowledge" (placeholder) | Art, texts | Phase 1 |
| D4 | Friendship rules: who can befriend whom; parent approval? what online status shows? | Requests between children, **parent approves**; only "online" dot | Friends feature, safety | Phase 0 |
| D5 | Staff answers (Gin, game modules, friend rules) | Proceed, verify early | Module plan | Phase 0 |
| D6 | Token storage in the browser | httpOnly cookies + CSRF protection | Auth implementation | Phase 1 |
| D7 | Parent progress view: frontend calls Game directly (Game checks the link with Identity), or Identity aggregates? | Call Game directly | Parent dashboard | Phase 3 |
| D8 | Challenge scoring formula and tie rule | 100 + speed bonus; draw on tie | Match engine | Phase 4 |
| D9 | Questions per level, pass mark, time per round | 5 questions, 3 to pass, 15 s | Game rules | Phase 3 |
| D10 | Art and sound: source and licences | Free-licensed assets + CREDITS file | Visuals | Phase 1 |
| D11 | Phaser for anything, or plain React + CSS animations? | Plain React first | Frontend game layer | Phase 1 |

### 15.2 Decision log

| Date | Decision | Why | Decided by |
|---|---|---|---|
| ____ | Project: kid-friendly educational adventure game, 3 islands | Team motivation; fits modules | All |
| ____ | Frontend: React + TypeScript + Tailwind | Team skills, ecosystem | All |
| ____ | Backend: Go + Gin (replaces NestJS) | Team choice | All |
| ____ | Split: 2 frontend, 2 backend | Parallel work | All |
| ____ | 3 services (Identity, Content, Game) + Nginx as gateway | Achievable for a team of 4 | Backend pair |
| ____ | | | |

---

## 16. Evaluation checklist

Run through this before the evaluation, from a **fresh clone**:

**Mandatory**
- [ ] `cp .env.example .env && make up` starts everything with one command.
- [ ] `https://localhost` works; HTTP redirects to HTTPS.
- [ ] Chrome console: zero errors and warnings on every page.
- [ ] Privacy Policy and Terms: real, project-specific, linked in the footer.
- [ ] Several users logged in at once; two matches at once; nothing corrupts.
- [ ] Forms reject invalid input on both sides (try bypassing the frontend with `curl`).
- [ ] Passwords are hashed in the database (show a row).
- [ ] `.env` is not in Git; `.env.example` is.
- [ ] Schema is clear; the README shows it.

**Security**
- [ ] Every protected endpoint refuses the wrong user (403) and no token (401).
- [ ] Correct answers never appear in any browser network response.
- [ ] Scores and progress can't be faked by sending custom requests.
- [ ] Login is rate-limited; tokens expire; logout revokes the refresh token.
- [ ] `/internal/*` is not reachable from the browser.
- [ ] Uploads checked for type and size.

**Team**
- [ ] Git history shows commits from all four, with clear messages.
- [ ] Each member can explain: the architecture, their features, and why we chose them.
- [ ] Each member has practised a small live change in their own area.
- [ ] Each module has a demo script and has been rehearsed.
- [ ] The README has every required section: the italic first line with logins, Description, Instructions, Resources (with AI usage), Team information, Project management, Technical stack, Database schema, Features list, Modules (with points and justification), Individual contributions.

---

## 17. Glossary

| Term | Meaning |
|---|---|
| **Service** | A separate backend program with one responsibility (Identity, Content, Game) |
| **Reverse proxy / Nginx** | The single public server; it receives every request and forwards it to the right service |
| **Endpoint** | One URL + method the backend answers, e.g. `POST /api/identity/children` |
| **API contract (OpenAPI)** | The written list of endpoints and data shapes both sides build against |
| **Handler / service / repository** | The three layers inside a Go service: HTTP, business rules, database |
| **ORM (GORM)** | A library that maps Go structs to database tables |
| **Migration** | A versioned SQL file that changes the database schema |
| **Seed** | Starting data (islands, levels, questions) loaded into the database |
| **Schema (PostgreSQL)** | A namespace of tables inside a database; one per service here |
| **JWT** | A signed token proving who the user is |
| **bcrypt** | A slow, salted password-hashing algorithm |
| **WebSocket** | A long-lived two-way connection for live updates |
| **Server-authoritative** | The server decides results; the browser only displays them |
| **Race condition** | A bug where two things happening at once corrupt data; `go test -race` detects many |
| **Walking skeleton** | The thinnest version of the whole system that runs end to end, built before features |
| **RTL** | Right-to-left layout, for Arabic |
| **i18n** | Internationalisation: making the app translatable |
| **PO / PM / Tech Lead** | Product Owner / Project Manager / Technical Lead |
| **Major / Minor module** | Optional subject features worth 2 / 1 points |

---

*Keep this file alive: when reality changes, change the file. A wrong document is worse than none.*
