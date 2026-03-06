# SentinelForge

**Secure homelab platform for running autonomous AI agents with strict governance, auditing, and observability**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)
![Status](https://img.shields.io/badge/status-alpha-orange.svg)

## Overview

SentinelForge is a zero-trust AI agent execution platform designed for secure experimentation with autonomous agents in homelab environments. It provides:

- **Strict governance**: Policy-as-code using OPA/Cerbos for tool access control
- **Comprehensive auditing**: Immutable logs of all agent actions and AI-driven output review
- **Full observability**: Prometheus, Loki, Tempo, and Grafana dashboards for agent behavior
- **Safe experimentation**: Read-only sandboxes, network isolation, and human-in-the-loop workflows
- **Modular architecture**: Pluggable agent frameworks (CrewAI, LangGraph), tools, and models

## Architecture

SentinelForge uses a layered architecture with strict trust boundaries:

```
User Layer → Control Plane → Agent Runtime → AI Layer → Observability
```

- **Control Plane**: FastAPI-based orchestration, policy engine, audit service
- **Agent Runtime**: CrewAI/LangGraph execution with tool gateway pattern
- **AI Layer**: Model router supporting local Ollama and cloud LLMs, with dual-model auditing
- **Observability**: Grafana stack with full telemetry (metrics, logs, traces)

See [docs/architecture.md](docs/architecture.md) for detailed diagrams and component descriptions.

## Key Features

### Security First
- Network segmentation via Docker networks / Kubernetes NetworkPolicies
- Read-only filesystem containers for agent workloads
- Secret management via Vault/Infisical integration
- Tool access controlled by external policy engine
- All tool calls logged and optionally require human approval

### AI Auditing
- Dual-model architecture: primary agent + secondary auditor
- Auditor reviews plans, tool calls, and outputs before release
- Verdict system: APPROVE / BLOCK / NEEDS_HUMAN
- Immutable audit trail with cryptographic verification

### Observable by Default
- OpenTelemetry instrumentation across all services
- Structured JSON logging with correlation IDs
- Grafana dashboards for agent performance, policy denials, model costs
- Distributed tracing for multi-step agent workflows

## Quick Start

### Prerequisites
- Docker 24+ and Docker Compose
- Python 3.11+
- 8GB+ RAM, 4+ CPU cores recommended
- (Optional) Kubernetes cluster for production deployment

### Phase 1: Basic Setup

```bash
# Clone and enter directory
git clone https://github.com/zebadee2kk/sentinelforge.git
cd sentinelforge

# Start core infrastructure
docker-compose -f infra/docker-compose.yml up -d

# Initialize database
make db-init

# Access UI
open http://localhost:8080
```

Default credentials: `admin@sentinelforge.local` / `changeme` (change immediately)

## Technology Stack

| Component | Technology |
|-----------|------------|
| API/Control Plane | FastAPI, Python 3.11+ |
| Agent Frameworks | CrewAI, LangGraph |
| Policy Engine | Open Policy Agent (OPA) |
| Authorization | Cerbos |
| Identity | Authentik (OIDC) |
| Database | PostgreSQL 16 |
| Object Storage | MinIO |
| Observability | Prometheus, Loki, Tempo, Grafana |
| Container Orchestration | Docker Compose → K3s/Kubernetes |
| Secret Management | Infisical / HashiCorp Vault |

## Development Roadmap

- [x] Phase 0: Architecture design and threat model
- [ ] Phase 1: Minimal secure skeleton (API, auth, observability)
- [ ] Phase 2: Tool Gateway and read-only agents
- [ ] Phase 3: AI auditor and policy engine integration
- [ ] Phase 4: Multi-agent workflows and limited write operations
- [ ] Phase 5: Kubernetes migration and hardening
- [ ] Phase 6: Open-source release and community building

See [docs/roadmap.md](docs/roadmap.md) for detailed milestones.

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Threat Model](docs/threat-model.md)
- [Tool Development Guide](docs/tools-development.md)
- [Policy Examples](docs/policies/)
- [Deployment Guide](docs/deployment.md)

## Contributing

SentinelForge is in early alpha. Contributions welcome once Phase 1 is complete. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

Security is paramount. Please report vulnerabilities privately to security@sentinelforge.dev (or via GitHub Security Advisories).

## License

MIT License - see [LICENSE](LICENSE)

## Acknowledgments

Built with:
- [CrewAI](https://github.com/crewAIInc/crewAI) for multi-agent orchestration
- [LangGraph](https://github.com/langchain-ai/langgraph) for stateful agent workflows
- [Open Policy Agent](https://www.openpolicyagent.org/) for policy enforcement
- [Cerbos](https://cerbos.dev/) for fine-grained authorization
- [Grafana Stack](https://grafana.com/oss/) for observability

---

**Status**: Alpha - Not production ready. Designed for secure homelab experimentation.
