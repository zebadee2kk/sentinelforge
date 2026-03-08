# Changelog

All notable changes to `sentinelforge` are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-03-07
### Added
- Initial SentinelForge architecture and core project structure
- Comprehensive documentation (architecture, threat model, observability design)
- Docker Compose infrastructure stack with PostgreSQL, MinIO, and observability components
- FastAPI service scaffold with health checks and telemetry configuration
- Observability configurations (Prometheus, Loki, Tempo, Grafana)
- Cerbos policy examples for tool access control
- Security research documentation and governance policies
- Database connection handling for asyncpg
- Application health checks and readiness probes

### Changed
- Telemetry configuration adjusted to be opt-in by default
- Database connection handling improved for asyncpg compatibility

[Unreleased]: https://github.com/zebadee2kk/sentinelforge/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/zebadee2kk/sentinelforge/releases/tag/v0.1.0
