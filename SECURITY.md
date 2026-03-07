# Security Policy

This document defines the initial security policy for SentinelForge. It is intended for homelab deployments but aligns with emerging best practices for enterprise AI agent security and EU AI Act governance.

## Objectives

- Prevent AI agents from compromising the homelab environment.
- Ensure all agent actions are authorized, logged, and auditable.
- Provide defense-in-depth against prompt injection, sandbox escape, and tool abuse.
- Lay groundwork for future compliance with the EU AI Act and similar regulations.[web:130][web:135][web:138]

## Scope

This policy applies to:

- All SentinelForge components (API, Orchestrator, Tool Gateway, Auditor, Model Router).
- All agent runtimes executing within the platform.
- All tools, including MCP-based tools, exposed to agents.

## Trust Model

- **Control Plane (API, Policy Engine, Audit Service)** is **trusted** and runs in a hardened environment.
- **Agent Runtime** is **untrusted**. Agents are treated as potentially malicious code.
- **Tool Gateway** is trusted and is the sole path between agents and external systems.
- **MCP Servers** are untrusted, even when self-hosted, and must be explicitly allowlisted.[web:51][web:108][web:115]

## Identity & Access Management

- Users authenticate via OIDC (Authentik) with MFA enabled where possible.[web:92][web:93][web:99]
- Agent identities are bound to user identities for audit (who asked the agent to act).[web:129][web:134]
- Role-based and attribute-based access control (RBAC/ABAC) is enforced via a policy engine (Cerbos or OPA) for:
  - Which agents a user may run.
  - Which tools an agent may invoke on behalf of a user.[web:69][web:129][web:134][web:140]

## Agent Execution

- Agents run in isolated containers with:
  - Non-root user, no privilege escalation.
  - Read-only root filesystem.
  - No host mounts or Docker socket access.
  - Limited CPU and memory.
- For high-risk workloads (code execution tools), migrate to microVM-based sandboxes (Firecracker or Kata Containers) as infrastructure permits.[web:77][web:80]
- Agent containers are considered ephemeral and disposable.

## Network Security

- Agent networks are segmented from production systems and sensitive data stores.[web:77][web:81]
- Default-deny egress policies on agent workloads; only Tool Gateway and Model Router are allowed.
- Tool Gateway maintains an outbound allowlist of approved external services.
- DNS is restricted to known resolvers and domains.

## Tool Governance

- Tools are defined centrally in the SentinelForge Tool Registry, not at the agent level.
- Each tool has:
  - A unique name and category.
  - A declared permission level (`read`, `write`, `admin`).
  - A JSON schema for inputs.
  - Rate limits per agent and per user.
- The policy engine decides whether a specific agent/user may invoke a given tool in a given context.[web:69][web:129][web:139]
- High-risk tools (e.g., `delete_database`, `system_shutdown`, financial transfers) are disabled by default and require explicit human approval per call.

## MCP-Specific Policies

- Only MCP servers on a static allowlist may be used.[web:51][web:107][web:115]
- Tool metadata from MCP servers is sanitized and rewritten before being injected into prompts.[web:108][web:110][web:114]
- All MCP tool calls are routed through the Tool Gateway and subject to the same policy checks and logging as native tools.[web:51][web:139]

## Prompt Injection Defenses

- All untrusted input (user prompts, tool outputs, web content) is clearly delimited in prompts and labeled as untrusted data.[web:114][web:117]
- A secondary "auditor" model reviews high-risk outputs for:
  - Secret or PII leakage.
  - Instructions that conflict with organizational policies.
  - Signs of prompt injection or model manipulation.[web:82][web:114][web:117]
- Outputs that fail audit are blocked or escalated for human review.

## Logging & Observability

- All significant events (runs, tool calls, policy decisions, auditor verdicts) are logged in an immutable audit log.[web:101][web:138]
- OpenTelemetry traces capture end-to-end execution for each run, including LLM calls and tool invocations.[web:83][web:89]
- Metrics (latency, token usage, error rates, policy denials) are surfaced via Prometheus/Grafana.[web:83][web:89]
- Anomaly detection rules are defined for:
  - Sudden spikes in tool usage.
  - Unusual access patterns.
  - Frequent policy denials or audit blocks.[web:128][web:136]

## Human-in-the-Loop Controls

- Deletion of data, configuration changes, and financial operations always require explicit human approval.
- Approval workflows are recorded in the audit log with user identity, timestamp, and rationale.
- Humans can override or halt agent operations at any time via SentinelForge’s control plane.[web:133][web:135][web:138]

## Compliance & Governance

- SentinelForge maintains:
  - Documented architecture and threat models.
  - Risk assessments for each class of agent and tool.
  - Configuration baselines and change management records.
- These artifacts support future alignment with the EU AI Act’s requirements for risk management, documentation, logging, and human oversight.[web:130][web:135][web:138]

This policy will evolve over time based on new research, incident learnings, and regulatory developments.
