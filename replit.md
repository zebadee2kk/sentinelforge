# SentinelForge

Secure homelab platform for running autonomous AI agents with strict governance, auditing, and observability.

## Architecture

- **Backend**: FastAPI (Python 3.12) serving on port 5000
- **Database**: PostgreSQL (Replit built-in)
- **Cache**: Redis 7.2 (started via start.sh)
- **No frontend**: API-only service with Swagger docs at `/docs`

## Project Layout

```
services/api/
  src/
    main.py          - FastAPI app entry point
    api/v1/          - API route handlers (health, auth, runs, agents, tools)
    core/
      config.py      - Pydantic settings (env-based)
      redis.py       - Redis connection dependency
      telemetry.py   - OpenTelemetry setup (disabled by default)
    db/
      session.py     - SQLAlchemy async engine/session
      base.py        - SQLAlchemy declarative base
infra/
  postgres/init.sql  - DB schema (users, agents, tools, runs)
start.sh             - Starts Redis + uvicorn for development
```

## Environment Variables

Required:
- `DATABASE_URL` - PostgreSQL connection string (provided by Replit)

Optional (external services not available in Replit):
- `REDIS_URL` - defaults to `redis://localhost:6379/0`
- `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY` - object storage
- `AUTHENTIK_URL`, `AUTHENTIK_TOKEN` - OIDC identity provider
- `OTEL_ENABLED` - set to `true` to enable OpenTelemetry tracing

## Key Endpoints

- `GET /` - service info
- `GET /health` - basic health check
- `GET /health/ready` - readiness check (db + redis)
- `GET /docs` - Swagger UI (enabled in DEBUG mode)
- `GET /metrics` - Prometheus metrics
- `POST /api/v1/auth/token` - auth placeholder
- `GET /api/v1/agents` - agent management (Phase 2)
- `GET /api/v1/runs` - run management (Phase 2)
- `GET /api/v1/tools` - tool management (Phase 2)

## Development Status

- Phase 0: Architecture design (done)
- Phase 1: Minimal secure skeleton - API, auth, observability (in progress)
- Phase 2+: Tool gateway, AI auditor, multi-agent workflows (future)

## Running Locally

```bash
bash start.sh
```

This starts Redis on port 6379 and uvicorn on port 5000 with hot reload.

## Changes from Original

- `config.py`: Made MinIO, Authentik, and Redis optional with sensible defaults
- `telemetry.py`: Made telemetry opt-in via `OTEL_ENABLED` env var
- `db/session.py`: Strip `sslmode` query param for asyncpg compatibility
- `api/v1/health.py`: Fixed non-awaitable `fetchone()` call
