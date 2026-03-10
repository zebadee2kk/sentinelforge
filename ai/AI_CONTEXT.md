# AI Context — sentinelforge

> **Read this first.** This file orients any AI assistant to this repository.

## Repository Purpose

**sentinelforge** is a threat intelligence and security signal aggregation platform. It ingests, normalises, enriches, and correlates security signals from multiple sources, providing a unified view of threat indicators and security posture.

## Start Here

| Document | Contents |
|----------|----------|
| [`README.md`](../README.md) | Project overview and setup |
| [`replit.md`](../replit.md) | Replit environment details |
| [`PROJECT_STATUS.md`](../PROJECT_STATUS.md) | Current status and priorities |
| [`ARCHITECTURE.md`](../ARCHITECTURE.md) | System architecture |

## Repository Structure

```
sentinelforge/
├── ai/                        ← AI context files (YOU ARE HERE)
├── services/                  ← Core platform services
├── infra/                     ← Infrastructure configuration
├── docs/                      ← Documentation
├── main.py                    ← Entry point
├── pyproject.toml             ← Python project config
├── Makefile                   ← Common commands
└── start.sh                   ← Quick start script
```

## Key Relationships

| Repo | Relationship |
|------|--------------|
| `portfolio-management` | Governance hub — tracks this repo's status |
| `kynee` | KYNEĒ may produce findings that sentinelforge ingests |
| `hamnet` | Infrastructure context — may host sentinelforge services |

## Critical Rules for This Repo

1. **No secrets in commits** — all credentials in `.env` (never committed)
2. **Read before write** — read `README.md` and relevant source before changes
3. **Read `ai/AI_RULES.md`** before any code changes
4. **Security data is sensitive** — threat intel, IOCs, and findings must be handled carefully
