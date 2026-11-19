# Shortcuts for the most common Docker Compose commands.
# Run `make` or `make help` to see the list.

COMPOSE = docker compose

.PHONY: help env up down logs ps db psql reset

help: ## Show the available commands
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  make %-8s %s\n", $$1, $$2}'

env: ## Create .env from .env.example if it does not exist yet
	@test -f .env || (cp .env.example .env && echo "Created .env from .env.example")

up: env ## Build and start everything in the background
	$(COMPOSE) up --build -d

down: ## Stop all containers (data is kept)
	$(COMPOSE) down

logs: ## Follow the logs of all containers (Ctrl+C to stop following)
	$(COMPOSE) logs -f

ps: ## Show which containers are running
	$(COMPOSE) ps

db: env ## Start only the database and run the migrations (works today)
	$(COMPOSE) up --build postgres migration

psql: ## Open a SQL shell in the database as the admin user
	$(COMPOSE) exec postgres sh -c 'psql -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"'

reset: ## DELETE all database data, then start the database and migrations again
	$(COMPOSE) down -v
	$(MAKE) db