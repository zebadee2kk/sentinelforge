# SentinelForge

**AI Agent Containment & Governance Platform**

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)
![Status](https://img.shields.io/badge/status-active_development-blue.svg)

---

## The Problem

Businesses are deploying AI agents faster than they can govern them. Without proper containment, autonomous AI systems can make unintended changes, exfiltrate data, or act outside their intended scope — often without anyone noticing until it's too late.

Most organisations have no audit trail, no policy enforcement, and no way to review what their AI agents actually did.

---

## What SentinelForge Does

SentinelForge is a secure execution platform for running autonomous AI agents with full governance, auditing, and observability built in from the ground up.

It answers a simple question: **"What did your AI agent do, why, and should it have been allowed to?"**

Key capabilities:

- **Policy-as-code enforcement** — AI agents can only use tools you explicitly permit
- **Immutable audit trail** — every agent action is logged with cryptographic verification
- **Dual-model auditing** — a secondary AI model reviews agent outputs before they're released
- **Human-in-the-loop controls** — critical actions require human approval before execution
- **Full observability** — real-time dashboards for agent behaviour, policy violations, and model costs
- **Network isolation** — agents run in sandboxed environments with strict boundary controls

---

## Who It's For

- Businesses deploying AI automation who need an auditable, defensible governance layer
- IT and security leaders who need to demonstrate AI oversight to boards or auditors
- Engineering teams building agentic workflows who want security guardrails from day one

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| API / Control Plane | FastAPI, Python 3.11+ |
| Agent Frameworks | CrewAI, LangGraph |
| Policy Engine | Open Policy Agent (OPA) |
| Authorization | Cerbos |
| Database | PostgreSQL 16 |
| Observability | Prometheus, Loki, Tempo, Grafana |
| Secret Management | Infisical / HashiCorp Vault |
| Container Orchestration | Docker Compose → Kubernetes |

---

## Status

Active development. Core architecture, policy enforcement, and audit framework are complete. Agent runtime and observability stack are in active build.

See [docs/roadmap.md](docs/roadmap.md) for the full delivery timeline.

---

## About

SentinelForge is built and maintained by [Richard Ham](https://richardham.co.uk) — Fractional IT & Security Leader with 25 years of enterprise IT experience. It was designed to solve a real governance gap observed across organisations adopting AI agents without adequate security controls.

---

## Security

To report a vulnerability, please use GitHub Security Advisories rather than opening a public issue.

## License

MIT License — see [LICENSE](LICENSE)
