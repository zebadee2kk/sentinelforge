# SentinelForge Roadmap

## Vision

Build a secure, observable, and governable platform for running autonomous AI agents in homelab and production environments.

---

## Phase 0: Foundation (Current) ✅

**Timeline**: Week 1  
**Status**: Complete

### Goals
- Define architecture and threat model
- Set up GitHub repository structure
- Document core concepts

### Deliverables
- [x] Architecture documentation
- [x] Threat model
- [x] Repository structure
- [x] README and contributing guidelines
- [x] Initial Docker Compose skeleton

---

## Phase 1: Secure Skeleton

**Timeline**: Weeks 2-3 (2-3 evenings + 1 weekend)  
**Status**: Not started

### Goals
- Minimal running system with authentication and observability
- No agents yet, just infrastructure
- Prove the control plane works

### Tasks

#### Infrastructure
- [ ] Docker Compose with:
  - [ ] Traefik (ingress, TLS)
  - [ ] Authentik (OIDC)
  - [ ] Postgres (database)
  - [ ] MinIO (object storage)
  - [ ] Prometheus, Loki, Tempo, Grafana

#### Services
- [ ] SentinelForge API (FastAPI)
  - [ ] `/health` endpoint
  - [ ] OIDC integration
  - [ ] Database models (runs, agents, tools)
  - [ ] OpenTelemetry instrumentation
- [ ] Audit Service
  - [ ] Append-only log table
  - [ ] Hash verification
  - [ ] API for writing and querying logs

#### Observability
- [ ] Grafana dashboards:
  - [ ] API health (request rate, latency, errors)
  - [ ] Postgres metrics
  - [ ] Basic system metrics (CPU, RAM, disk)

#### Testing
- [ ] Smoke test: curl API with valid JWT
- [ ] Verify logs in Loki
- [ ] Verify metrics in Prometheus

### Success Criteria
- User can log in via Authentik
- API returns 200 on `/health`
- Logs visible in Grafana
- No secrets in environment variables or code

---

## Phase 2: Read-Only Agents

**Timeline**: Weeks 4-5  
**Status**: Not started

### Goals
- Add agent runtime with CrewAI or LangGraph
- Implement Tool Gateway with 2-3 read-only tools
- Prove agents can run safely without write access

### Tasks

#### Tool Gateway Service
- [ ] FastAPI service
- [ ] Tools:
  - [ ] `http_get` (allowlisted domains)
  - [ ] `github_read` (repo search, file read)
  - [ ] `file_read` (limited to `/mnt/readonly`)
- [ ] Request/response logging to Audit Service
- [ ] Basic rate limiting (per tool, per run)

#### Orchestrator Service
- [ ] Integrate LangGraph
- [ ] Define simple graph:
  - [ ] Plan → Tool calls → Summarize
- [ ] Tool call hooks:
  - [ ] Log to Audit Service
  - [ ] Policy check (stub for now, always allow read tools)
- [ ] OpenTelemetry tracing

#### Model Router
- [ ] Support local Ollama (DeepSeek)
- [ ] Support cloud API (OpenAI or Anthropic)
- [ ] Token usage tracking
- [ ] Response caching (optional)

#### Security
- [ ] Agent containers:
  - [ ] Read-only root filesystem
  - [ ] No outbound network except Tool Gateway + Model Router
  - [ ] Run as non-root user
- [ ] Docker network isolation

#### Observability
- [ ] Dashboards:
  - [ ] Agent run overview (count, success rate, duration)
  - [ ] Tool usage by type
  - [ ] Model token usage and cost estimate

### Success Criteria
- User submits task: "Summarize GitHub repo X"
- Agent uses `github_read` tool
- Output returned to user
- All tool calls visible in Grafana and audit log
- Agent cannot write files or access non-allowlisted URLs

---

## Phase 3: Policy Engine & AI Auditor

**Timeline**: Weeks 6-8  
**Status**: Not started

### Goals
- Add Open Policy Agent for tool authorization
- Implement Auditor Service (secondary LLM)
- Enforce policies on tool access

### Tasks

#### Policy Engine (OPA)
- [ ] Deploy OPA sidecar or standalone container
- [ ] Define initial policies:
  - [ ] `tools.rego`: Allow read-only tools for all agents
  - [ ] `agents.rego`: Define agent roles and capabilities
- [ ] Integrate with Tool Gateway:
  - [ ] Before each tool call, query OPA
  - [ ] Deny and log if policy rejects

#### Cerbos Integration (Alternative)
- [ ] Optional: Use Cerbos instead of OPA for fine-grained RBAC
- [ ] Define resources, roles, actions
- [ ] Integrate with Tool Gateway

#### Auditor Service
- [ ] Python service with secondary LLM
- [ ] Input: agent plan, tool call log, final output
- [ ] Output: verdict (APPROVE / BLOCK / NEEDS_HUMAN) + rationale
- [ ] Write to Audit Service
- [ ] Integrate with Orchestrator:
  - [ ] After agent completes, call Auditor
  - [ ] If BLOCK, don't return output to user
  - [ ] If NEEDS_HUMAN, flag in UI for review

#### UI Enhancement
- [ ] Audit log viewer
- [ ] Policy decision log
- [ ] Human approval queue for NEEDS_HUMAN runs

#### Observability
- [ ] Dashboard:
  - [ ] Policy denials (by tool, by agent)
  - [ ] Auditor verdicts (approve/block/needs-human)
  - [ ] Average audit latency

### Success Criteria
- Agent attempts to use write tool → OPA denies → logged
- Agent produces output → Auditor reviews → APPROVE → user receives
- Policy change in Git → reload OPA → new policy enforced

---

## Phase 4: Multi-Agent & Limited Writes

**Timeline**: Weeks 9-11  
**Status**: Not started

### Goals
- Support multi-agent workflows (CrewAI crews)
- Add limited write tools with human-in-the-loop approval
- Demonstrate safe mutation operations

### Tasks

#### Multi-Agent Support
- [ ] Define agent roles: Researcher, Analyst, PatchAuthor
- [ ] CrewAI crew definitions
- [ ] Per-agent tool assignments
- [ ] Crew execution flow with hand-offs

#### Write Tools (High Risk)
- [ ] `github_create_pr` (creates PR, doesn't merge)
- [ ] `file_write` (limited to `/mnt/sandbox`)
- [ ] All write tools require:
  - [ ] Human approval before execution
  - [ ] Audit log with approval metadata

#### Human-in-the-Loop UI
- [ ] Approval queue dashboard
- [ ] Show: agent intent, proposed action, risk level
- [ ] Approve / Reject / Request changes
- [ ] Approval logged immutably

#### Policy Updates
- [ ] New policy: write tools allowed only for `PatchAuthor` agent
- [ ] New policy: write tools require approval

#### Observability
- [ ] Dashboard:
  - [ ] Pending approvals
  - [ ] Write tool usage
  - [ ] Average time to approval

### Success Criteria
- Multi-agent crew completes research → analysis → PR draft workflow
- PatchAuthor proposes PR → human approves → PR created in GitHub
- All write actions logged with approval metadata

---

## Phase 5: Kubernetes Migration

**Timeline**: Weeks 12-14  
**Status**: Not started

### Goals
- Migrate from Docker Compose to K3s or full Kubernetes
- Harden with NetworkPolicies and PodSecurity
- Prepare for production-like deployment

### Tasks

#### Kubernetes Setup
- [ ] K3s cluster on Proxmox or Talos on bare metal
- [ ] Namespaces:
  - [ ] `sentinelforge-control`
  - [ ] `sentinelforge-agents`
  - [ ] `observability`
  - [ ] `auth`

#### Helm Charts
- [ ] Grafana stack (Prometheus, Loki, Tempo, Grafana)
- [ ] Authentik or Keycloak
- [ ] Postgres operator (e.g., Zalando, CloudNativePG)

#### Security Hardening
- [ ] NetworkPolicies:
  - [ ] Agents → only Tool Gateway + Model Router
  - [ ] Tool Gateway → explicit allowlist
- [ ] PodSecurity:
  - [ ] `sentinelforge-agents` namespace: Restricted profile
  - [ ] Non-root, read-only FS, no capabilities
- [ ] Secret management:
  - [ ] Deploy Vault or Infisical
  - [ ] Migrate all secrets from Docker env vars

#### CI/CD
- [ ] GitHub Actions:
  - [ ] Build and push Docker images
  - [ ] Helm chart linting
  - [ ] Deploy to staging namespace

#### Observability
- [ ] Distributed tracing across pods
- [ ] Pod metrics (CPU, RAM, restarts)
- [ ] Alert rules (high error rate, pod crash loop)

### Success Criteria
- All services running in Kubernetes
- Agents cannot access prohibited network endpoints
- Secrets stored in Vault, not in code or env vars
- CI/CD pipeline deploys on commit to main

---

## Phase 6: Open Source Release

**Timeline**: Weeks 15-16  
**Status**: Not started

### Goals
- Prepare for public release
- Documentation and contributor onboarding
- Initial community building

### Tasks

#### Documentation
- [ ] Install guide (Docker Compose and Kubernetes)
- [ ] Configuration examples
- [ ] Tool development guide
- [ ] Policy writing guide
- [ ] Troubleshooting FAQ

#### Contributor Experience
- [ ] CONTRIBUTING.md with setup instructions
- [ ] Code of conduct
- [ ] Issue templates (bug, feature request, security)
- [ ] PR template
- [ ] GitHub Actions for tests and linting

#### Security
- [ ] Security policy (SECURITY.md)
- [ ] Responsible disclosure process
- [ ] Third-party security audit (if budget allows)

#### Community
- [ ] GitHub Discussions enabled
- [ ] Project website or docs site (GitHub Pages)
- [ ] Social media presence (optional)
- [ ] Blog post or demo video

#### Polish
- [ ] UI/UX improvements
- [ ] Pre-built Grafana dashboards packaged
- [ ] Example agent workflows (research, code review, report generation)

### Success Criteria
- Repository is public
- External contributor submits first PR
- Documentation allows user to install and run SentinelForge in < 30 minutes
- At least one blog post or demo video published

---

## Future (Post-Launch)

### Potential Features
- Multi-tenancy: per-user namespaces and policies
- Agent marketplace: community-contributed agents and tools
- Advanced auditing: ML-based anomaly detection
- Integration: GitHub App for automated PR reviews
- Scheduling: cron-like agent runs
- Cost optimization: auto-select cheapest model that meets quality bar
- Fine-tuning: train custom models on approved outputs

### Research Areas
- Zero-knowledge agent execution (privacy-preserving)
- Formal verification of agent behavior
- Adversarial robustness testing

---

## Milestones Summary

| Phase | Timeline | Key Deliverable |
|-------|----------|----------------|
| Phase 0 | Week 1 | Architecture and repo setup |
| Phase 1 | Weeks 2-3 | Secure skeleton with auth and observability |
| Phase 2 | Weeks 4-5 | Read-only agents with Tool Gateway |
| Phase 3 | Weeks 6-8 | Policy engine and AI auditor |
| Phase 4 | Weeks 9-11 | Multi-agent and limited writes |
| Phase 5 | Weeks 12-14 | Kubernetes migration and hardening |
| Phase 6 | Weeks 15-16 | Open-source release |

**Total Estimated Time**: ~4 months (part-time, evenings + weekends)

---

## How to Contribute

We're in Phase 0. Once Phase 1 is complete, we'll open for contributions. Follow this repo for updates.

Interested in helping? Open a Discussion on GitHub to introduce yourself.
