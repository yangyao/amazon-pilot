# Repository Guidelines

## Source of Truth
- Requirements: `docs/questions.md` (primary product scope). Design: `docs/*.md` (architecture, API, DB). Follow these before coding.
- API definitions live in `api/openapi/*.api`. Generate server stubs via `scripts/goctl-centralized.sh -s <service>`; do not edit generated files under `internal/<service>/{handler,types}`.

## Project Structure
- Backend (Go): `cmd/<service>/main.go` (entrypoints); `internal/<service>/{handler,logic,svc,types,config}`; shared libs in `internal/pkg`, `pkg`.
- Frontend (Next.js 14 + TS): `frontend/src/{app,components,lib}` with Tailwind.
- Ops: `deployments/compose` (Docker Compose), `docker/` (Dockerfiles), `scripts/` (build/run/migrations), `docs/`.
- Data: SQL migrations in `deployments/migrations/` (legacy in `migrations/`).

## Build, Run, and Migrate
- Build all: `bash scripts/build-all.sh` → artifacts in `bin/`.
- Local dev: `bash scripts/service-manager.sh start` (also `status|stop|restart|list|monitor`). Avoid manual `go run`; use the manager.
- Frontend: `cd frontend && pnpm dev` (port 4000); build with `pnpm build`.
- Full stack: `docker-compose -f deployments/compose/docker-compose.yml up -d`.
- Migrations: add files under `deployments/migrations/NNN_description.sql`; run `bash scripts/run-migrations.sh`; update DB docs.

## Coding Style & Conventions
- Go: `go fmt ./...` and `go vet ./...`. Handlers only orchestrate; put business rules in `logic/`; wiring in `svc/`. Enforce JSON structured logging via `internal/pkg/logger`; avoid `fmt.Println`/standard log. No hardcoded config—use env and per‑service `etc`.
- API: prefix routes with `/api/<service>` (see `api/openapi/*.api`). All frontend requests go through the gateway using `frontend/src/lib/*-api.ts` helpers; avoid raw fetch to internal services.
- Frontend: TypeScript + ESLint (`pnpm lint`, `pnpm type-check`); files lowercase (`components/ui/button.tsx`), exported symbols PascalCase; 2‑space indent.

## Testing
- Go tests colocated as `*_test.go`; prefer table‑driven tests/subtests. Run: `go test ./... -race -cover`. Target ≥70% coverage on changed packages where practical.
- Frontend: rely on type checks and lint; colocate tests if added.

## Commits & PRs
- Commits: short, imperative; optional scope (`gateway: add rate limit`). Chinese/English both fine. Group related changes.
- PRs: describe context, services touched, migration impact, and validation steps. Link relevant docs (especially `docs/questions.md`) and include screenshots or sample API calls for UI/API changes.

## Security & Config
- Never commit secrets. Use `env.example` locally; production uses `deployments/compose/.env.production` and CI secrets. Keep Apify/OpenAI/JWT in env. Validate inputs and avoid logging sensitive data.
