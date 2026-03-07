# Security Architecture

This document summarizes current best practices and research that inform SentinelForge’s security model for autonomous AI agents.

## Zero-Trust Agent Model

Recent security guidance emphasizes that AI agents should be treated as **untrusted code and untrusted principals**, even when they run inside your own infrastructure.[web:77][web:128][web:136]

Key principles:

- **Never trust, always verify**: Every agent action, tool call, and data access must be explicitly authorized.
- **Least privilege**: Agents get the minimum permissions required for a specific task, not a general-purpose superuser role.[web:77][web:133][web:139]
- **Assume breach**: Design for the scenario where an agent is compromised or behaves maliciously.
- **Continuous monitoring**: Log and trace all significant agent activity and enforce anomaly detection.[web:77][web:128][web:136]

In SentinelForge this translates into:

- Isolating agent runtimes in low-trust sandboxes.
- Enforcing policy checks before each tool call.
- Recording immutable audit trails for all decisions.
- Requiring human approval for high-risk actions.

## Sandboxing and Isolation

Standard containers are not sufficient for truly untrusted AI-generated code because they share the host kernel.[web:77][web:80]

Best practices:

- **MicroVMs (Firecracker, Kata Containers)**:
  - Strongest isolation with dedicated kernels per workload.
  - Recommended for production environments running untrusted AI-generated code or tools with broad system access.[web:77]

- **gVisor / user-space kernels**:
  - Intercepts syscalls, providing stronger isolation than vanilla containers without full VM overhead.[web:77][web:80]

- **Hardened containers**:
  - Acceptable only for trusted internal automation, not for arbitrary LLM-generated code.
  - Must use seccomp/AppArmor, drop capabilities, read-only rootfs, and strict NetworkPolicies.[web:77][web:81]

SentinelForge initially targets hardened containers for homelab use, with a roadmap to integrate microVM-based sandboxes for code-executing tools.

Minimum sandbox baseline:

- Non-root user, no privilege escalation.
- Read-only root filesystem, with only ephemeral `/tmp` writable.
- No `hostPath` volumes or Docker socket access.
- Egress allowlist for only Tool Gateway and Model Router.

## Network Controls

Sandbox guidance for AI agents recommends a **zero-trust network model** where all connections are explicitly allowed.[web:77][web:81]

Controls:

- **Egress filtering**:
  - Block all outbound connections by default.
  - Whitelist only required API endpoints and internal services.

- **DNS restrictions**:
  - Restrict DNS resolution to known internal and approved external domains.

- **Segmentation**:
  - Separate agent networks from production systems, secrets stores, and sensitive data.

In SentinelForge:

- Agent namespace can only reach Tool Gateway and Model Router.
- Tool Gateway applies its own outbound allowlist.

## Tool Authorization with Cerbos / OPA

AI agents pose new authorization challenges because they act on behalf of users and chain operations across multiple tools and data sources.[web:69][web:129][web:131]

Cerbos and OPA are both suitable policy engines:

- **Cerbos**:
  - Attribute-based policies in YAML.
  - Designed to authorize AI agent tool calls and downstream API calls.[web:129][web:134][web:140]
  - Every decision is logged with context, forming an audit trail.[web:129][web:139]

- **OPA**:
  - Rego policies evaluated locally or via sidecar.[web:74]
  - Well-suited to Kubernetes and infrastructure enforcement.

Recommended pattern:

1. Before each tool call, the SentinelForge Tool Gateway sends: user identity, agent role, tool name, and target resource to the PDP (Cerbos/OPA).[web:69][web:129][web:131]
2. PDP evaluates policies and returns `allow` or `deny`.
3. The gateway enforces the decision and logs it to the audit log.

This ensures that agents cannot overreach beyond what the requesting user is allowed to do.[web:129][web:134][web:140]

## Prompt Injection and MCP

Model Context Protocol (MCP) makes it easy to expose tools, but also introduces notable prompt injection risks via tool metadata and untrusted server responses.[web:108][web:110][web:115]

Risks:

- Malicious tool descriptions that instruct the LLM to exfiltrate secrets or ignore safety rules.[web:108][web:110]
- Tools that do more than advertised (e.g., sending data to attacker-controlled endpoints).[web:112][web:115]
- Indirect prompt injection via untrusted content (webpages, emails) fetched through MCP tools.[web:107][web:114][web:117]

Mitigations:

- Allowlist only vetted MCP servers; no dynamic user-provided endpoints.[web:51][web:107][web:115]
- Sanitize and rewrite tool metadata before exposing it to the LLM.
- Validate tool inputs against schemas, and strip unexpected fields.
- Use CrewAI Tool Call Hooks to call the PDP before every MCP tool invocation.[web:44][web:51][web:67]
- Wrap MCP responses in prompt shields with clear delimiters and instructions that the content is untrusted data, not commands.[web:114][web:117]

## EU AI Act and Governance Implications

The EU AI Act’s obligations begin to apply from 2026 and make AI governance and risk management legal requirements rather than best-effort guidelines.[web:130][web:135][web:138][web:141]

Key themes relevant to SentinelForge:

- **Risk classification and governance**:
  - Organizations must identify AI risks, assign accountability, and maintain oversight across the lifecycle of each AI system.[web:130][web:135]

- **Documentation and traceability**:
  - High-risk systems must maintain detailed technical documentation, risk management processes, and automatic logging of relevant events.[web:135][web:138]

- **Human oversight**:
  - High-risk AI must remain under meaningful human control, with clear override mechanisms and trained supervisors.[web:135][web:138]

- **Regulatory sandboxes**:
  - Member States are expected to provide AI sandboxes for testing under supervision, starting around August 2026.[web:141]

SentinelForge is designed as a governance-friendly platform:

- Immutable audit logs and policy decision records.
- Dual-model auditing and human-in-the-loop approvals.
- Clear separation of control plane (trusted) and agent runtime (untrusted).

These features align well with the EU AI Act’s emphasis on documentation, traceability, and oversight, even if SentinelForge is initially operated as a homelab and later evolves into a commercial offering.

## Summary of Security Design Decisions

Based on current research and best practices:

- Agents are treated as untrusted and run in hardened, isolated environments.[web:77][web:81][web:128]
- All tool use is mediated by a Tool Gateway with policy checks from Cerbos/OPA.[web:69][web:129][web:139]
- Prompt injection is mitigated with MCP allowlisting, metadata sanitization, schema enforcement, and prompt shields.[web:107][web:108][web:114][web:115]
- Comprehensive logging and tracing make agent behavior auditable and explainable.
- Human approvals are mandatory for high-risk actions such as destructive operations or financial transactions.[web:77][web:133][web:135]

This document should evolve as new attack techniques and regulatory expectations emerge.
