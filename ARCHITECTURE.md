# Architecture — sentinelforge

> For full setup detail, see `README.md`.
> For Replit environment, see `replit.md`.

## Overview

sentinelforge is a threat intelligence and security signal aggregation platform. It ingests, normalises, enriches, and correlates security signals from multiple sources.

## Directory Structure

```
sentinelforge/
├── services/                  ← Core platform services
├── infra/                     ← Infrastructure configuration
├── docs/                      ← Documentation
├── main.py                    ← Entry point
├── pyproject.toml             ← Python project config (uv)
├── Makefile                   ← Common commands
└── start.sh                   ← Quick start
```

## Stack

| Layer | Technology |
|-------|------------|
| Language | Python 3.11+ |
| Package manager | uv (uv.lock present) |
| Development | Replit-compatible |
| Infrastructure | See `infra/` |
