# SentinelForge Architecture

## Overview

SentinelForge is built on a layered, zero-trust architecture where autonomous AI agents operate within strict security boundaries enforced by policy engines, tool gateways, and audit services.

## High-Level Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                        USER LAYER                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ VS Code  │  │ Browser  │  │  GitHub  │  │  CLI     │    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
└───────┼─────────────┼─────────────┼─────────────┼───────────┘
        │             │             │             │
        └─────────────┴──────┬──────┴─────────────┘
                             │ HTTPS/OIDC
        ┌────────────────────▼────────────────────┐
        │         Traefik / Nginx Ingress         │
        │         (TLS, Auth, Rate Limit)         │
        └────────────────────┬────────────────────┘
┌────────────────────────────┼────────────────────────────────┐
│                    CONTROL PLANE                             │
│  ┌──────────────────────┐ │ ┌──────────────────────┐        │
│  │  Authentik/Keycloak  │◄┼─┤  SentinelForge API   │        │
│  │       (OIDC)         │ │ │     (FastAPI)        │        │
│  └──────────────────────┘ │ └──────┬───────────────┘        │
│                            │        │                         │
│  ┌──────────────────────┐ │ ┌──────▼───────────────┐        │
│  │   Policy Engine      │◄┼─┤  Orchestrator Svc    │        │
│  │  (OPA/Cerbos)        │ │ │  (CrewAI/LangGraph)  │        │
│  └──────────────────────┘ │ └──────┬───────────────┘        │
│                            │        │                         │
│  ┌──────────────────────┐ │ ┌──────▼───────────────┐        │
│  │   Audit Service      │◄┼─┤   Tool Gateway       │        │
│  │ (Postgres + MinIO)   │ │ │  (Policy enforced)   │        │
│  └──────────────────────┘ │ └──────┬───────────────┘        │
└────────────────────────────┼────────┼────────────────────────┘
                             │        │
┌────────────────────────────┼────────▼────────────────────────┐
│                      AGENT RUNTIME                            │
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌──────────────┐    │
│  │  Researcher   │  │  Analyst      │  │  PatchAuthor │    │
│  │  Agent        │  │  Agent        │  │  Agent       │    │
│  │  (read-only)  │  │  (read-only)  │  │  (mutating)  │    │
│  └───────┬───────┘  └───────┬───────┘  └──────┬───────┘    │
│          │                  │                  │             │
│          └──────────────────┴────────┬─────────┘             │
│                                      │                       │
│  Network: Restricted, only Tool Gateway + Model Router      │
│  Filesystem: Read-only root, writable /tmp only             │
└──────────────────────────────────────┼──────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────┐
│                         AI LAYER                             │
│  ┌──────────────────────┐       ┌──────────────────────┐    │
│  │   Model Router       │       │  Auditor Service     │    │
│  │  ┌────────────────┐  │       │  (Secondary LLM)     │    │
│  │  │ Local Ollama   │  │       │                      │    │
│  │  │ DeepSeek/Qwen  │  │       │  Reviews:            │    │
│  │  └────────────────┘  │       │  - Agent plans       │    │
│  │  ┌────────────────┐  │       │  - Tool call logs    │    │
│  │  │ Cloud APIs     │  │       │  - Final outputs     │    │
│  │  │ OpenAI/Anthropic│ │       │                      │    │
│  │  └────────────────┘  │       │  Returns: APPROVE/   │    │
│  │                      │       │          BLOCK/      │    │
│  └──────────────────────┘       │          NEEDS_HUMAN │    │
│                                 └──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────┐
│                  OBSERVABILITY STACK                         │
│  ┌────────────┐  ┌─────────┐  ┌────────┐  ┌──────────┐     │
│  │ Prometheus │  │  Loki   │  │ Tempo  │  │ Grafana  │     │
│  │ (Metrics)  │  │ (Logs)  │  │(Traces)│  │(Dashboards)    │
│  └─────▲──────┘  └────▲────┘  └───▲────┘  └──────────┘     │
│        │              │           │                          │
│        └──────────────┴───────────┘                          │
│              Grafana Agent / OTEL                            │
└─────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### Control Plane

#### SentinelForge API
- **Technology**: FastAPI + Uvicorn
- **Purpose**: Central orchestration, job management, UI backend
- **Responsibilities**:
  - Accept run requests from users
  - Coordinate with Policy Engine before execution
  - Trigger orchestrator service
  - Return results to users
  - Manage agent/crew configurations

#### Policy Engine (OPA/Cerbos)
- **Technology**: Open Policy Agent or Cerbos
- **Purpose**: Centralized authorization decisions
- **Responsibilities**:
  - Evaluate: "Can agent X use tool Y on resource Z?"
  - Policy-as-code versioned in Git
  - All decisions logged for audit

#### Audit Service
- **Technology**: Python service + Postgres + MinIO
- **Purpose**: Immutable audit trail
- **Storage**:
  - Postgres: Append-only table (run metadata, decisions, verdicts)
  - MinIO: Large artifacts (prompts, tool transcripts, outputs)
- **Features**:
  - Cryptographic hashing for tamper detection
  - Retention policies
  - Export for compliance

### Agent Runtime

#### Orchestrator Service
- **Technology**: CrewAI and/or LangGraph
- **Purpose**: Execute agent workflows
- **Features**:
  - Pluggable framework (adapter pattern)
  - Tool call hooks for policy enforcement
  - Task guardrails for output validation
  - Full telemetry via OpenTelemetry

#### Tool Gateway
- **Technology**: Python FastAPI service
- **Purpose**: Safe, controlled access to external resources
- **Responsibilities**:
  - Implement logical tools (git, http, filesystem, cloud APIs)
  - Enforce read-only vs write permissions
  - Rate limiting per tool/agent
  - Full request/response logging
- **Security**:
  - Agents never get raw secrets
  - All calls validated against OPA policies
  - Network allowlists per tool

### AI Layer

#### Model Router
- **Technology**: Python service with OpenAI/Anthropic/Ollama clients
- **Purpose**: Route LLM calls to appropriate providers
- **Features**:
  - Cost tracking per model/provider
  - Automatic failover
  - Response caching
  - Metadata annotation (purpose, routing decision)

#### Auditor Service
- **Technology**: Python service with secondary LLM
- **Purpose**: AI-driven review of agent outputs
- **Workflow**:
  1. Receives agent plan + tool log + output
  2. Calls secondary LLM (different provider than primary)
  3. Returns verdict: APPROVE / BLOCK / NEEDS_HUMAN
  4. Writes rationale to Audit Service

### Observability Stack

#### Prometheus
- Metrics: run counts, success rates, latency, token usage, policy denials

#### Loki
- Structured JSON logs from all services
- Correlation IDs for tracing requests across services

#### Tempo
- Distributed traces via OpenTelemetry
- Visualize multi-step agent workflows

#### Grafana
- Pre-built dashboards:
  - Agent performance overview
  - Tool usage and errors
  - Policy denials and audit activity
  - Model costs and provider health

## Network Architecture

### Docker Compose (Phase 1)

```
┌─────────────────────────────────────────┐
│   sentinelforge-network (bridge)        │
│                                         │
│  ┌──────────┐    ┌──────────┐          │
│  │ traefik  ├────┤   api    │          │
│  │  :80/:443│    │  :8000   │          │
│  └────┬─────┘    └────┬─────┘          │
│       │               │                 │
│       │          ┌────▼─────┐           │
│       │          │orchestrator│         │
│       │          │  :8001   │           │
│       │          └────┬─────┘           │
│       │               │                 │
│       │          ┌────▼─────┐           │
│       │          │tool-gateway│        │
│       │          │  :8002   │           │
│       │          └──────────┘           │
│       │                                 │
│  ┌────▼─────┐    ┌──────────┐          │
│  │ authentik│    │ postgres │          │
│  │  :9000   │    │  :5432   │          │
│  └──────────┘    └──────────┘          │
│                                         │
│  External access only via traefik       │
└─────────────────────────────────────────┘
```

### Kubernetes (Phase 5)

- **Namespaces**:
  - `sentinelforge-control`: API, policy, audit
  - `sentinelforge-agents`: Orchestrator, tool gateway (highly restricted)
  - `observability`: Grafana stack
  - `auth`: Authentik/Keycloak

- **NetworkPolicies**:
  - Agents → only Tool Gateway + Model Router
  - Tool Gateway → explicitly allowed external hosts
  - No direct internet from agent namespace

- **PodSecurityStandards**:
  - `sentinelforge-agents`: **Restricted** profile
    - Non-root user
    - Read-only root filesystem
    - No privilege escalation
    - Drop all capabilities

## Security Boundaries

### Trust Levels

| Component | Trust Level | Rationale |
|-----------|-------------|----------|
| User | Medium | Authenticated, but can request risky operations |
| Control Plane | High | Enforces policy, isolated from agents |
| Agent Runtime | **Low** | Untrusted; AI-generated actions |
| Tool Gateway | High | Policy enforcement point |
| Observability | Medium | Read-only monitoring data |

### Data Flow Security

1. **User request** → TLS → Traefik → OIDC check → API
2. **API** → OPA policy check → If allowed → Orchestrator
3. **Orchestrator** → Agent (untrusted container)
4. **Agent** → Tool call → Tool Gateway → OPA check → Execute or deny
5. **Tool Gateway** → Log to Audit Service (immutable)
6. **Agent** → Output → Auditor Service → Verdict → API → User

Every arrow is logged. Every decision is auditable.

## Deployment Models

### Homelab (Proxmox)

- Single VM (Ubuntu 22.04, 4 vCPU, 16GB RAM)
- Docker Compose for all services
- Separate VLAN from production homelab resources
- No direct access to NAS, Vaultwarden, or other sensitive services

### Kubernetes (Production-Ready)

- K3s or full Kubernetes cluster
- Helm charts for Grafana stack
- Separate node pools for control plane vs agent workloads
- Network policies enforcing zero-trust
- Pod security admission with Restricted profile

## Scalability Considerations

Phase 1 targets single-node homelab. Future scaling:

- **Horizontal**: Multiple orchestrator replicas, job queue (Celery/Redis)
- **Vertical**: GPU-enabled nodes for local LLM inference
- **Hybrid**: Control plane on-prem, model inference in cloud with VPN

## Disaster Recovery

- **Postgres**: WAL archiving to MinIO or QNAP NAS
- **Audit logs**: Immutable, replicated to off-site storage
- **Configuration**: All policy, agent definitions in Git
- **Secrets**: Backed up via Vault snapshots (encrypted)

## Next Steps

See [roadmap.md](roadmap.md) for implementation phases.
