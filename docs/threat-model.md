# SentinelForge Threat Model

## Purpose

This document identifies assets, threat actors, attack vectors, and mitigations for SentinelForge.

## Assets

### Critical Assets

1. **Secrets and API Keys**
   - LLM provider API keys (OpenAI, Anthropic, etc.)
   - GitHub tokens
   - Cloud provider credentials
   - Database passwords
   - Encryption keys

2. **Homelab Infrastructure**
   - Proxmox hypervisor
   - QNAP NAS with personal data
   - Vaultwarden password database
   - Other VMs/LXCs on same network

3. **Audit Logs**
   - Agent activity records
   - Policy decisions
   - Tool call transcripts
   - User actions

4. **User Data**
   - Agent configurations
   - Workflow definitions
   - Custom policies

### Secondary Assets

- Model inference compute (GPU VM)
- Observability data (metrics, logs, traces)
- UI session tokens

## Threat Actors

### TA-1: Compromised Agent
**Profile**: AI agent with malicious or buggy LLM output  
**Motivation**: Exfiltrate secrets, access homelab resources, cause damage  
**Capability**: Can craft prompts, call tools, generate code

### TA-2: External Attacker
**Profile**: Internet-based adversary  
**Motivation**: Gain access to homelab, steal credentials, pivot to internal network  
**Capability**: Exploit web vulnerabilities, brute force, supply chain attacks

### TA-3: Insider/User Error
**Profile**: Legitimate user making mistakes  
**Motivation**: Unintentional misconfiguration, accidental data exposure  
**Capability**: Create agents, define policies, access UI

### TA-4: Supply Chain Compromise
**Profile**: Malicious dependency (Python package, Docker image)  
**Motivation**: Backdoor, data exfiltration  
**Capability**: Arbitrary code execution in containers

## Attack Scenarios

### Scenario 1: Agent Escapes Sandbox

**Threat Actor**: TA-1 (Compromised Agent)  
**Attack Vector**:
1. Agent receives malicious prompt or hallucinates
2. Attempts to access filesystem outside `/tmp`
3. Tries to call Proxmox API or access NAS

**Impact**: High - Full homelab compromise

**Mitigations**:
- ✅ Read-only root filesystem on agent containers
- ✅ NetworkPolicies: agents can only reach Tool Gateway + Model Router
- ✅ No host mounts or `hostPath` volumes
- ✅ Drop all Linux capabilities
- ✅ Agent containers run as non-root user

**Residual Risk**: Low

---

### Scenario 2: Tool Gateway Bypass

**Threat Actor**: TA-1 (Compromised Agent)  
**Attack Vector**:
1. Agent discovers direct access to external API (GitHub, cloud)
2. Bypasses Tool Gateway and policy engine
3. Executes unauthorized actions

**Impact**: Medium - Unauthorized API usage, data leakage

**Mitigations**:
- ✅ Agents have no outbound internet except to Tool Gateway
- ✅ Tool Gateway enforces OPA policy on every call
- ✅ Secrets never exposed to agent containers
- ✅ All tool calls logged immutably

**Residual Risk**: Low

---

### Scenario 3: Secret Exfiltration via Output

**Threat Actor**: TA-1 (Compromised Agent)  
**Attack Vector**:
1. Agent accesses secret through legitimate tool call
2. Includes secret in final output to user
3. User unknowingly shares output publicly

**Impact**: High - API key compromise, credential theft

**Mitigations**:
- ✅ Auditor service scans outputs for secrets before release
- ✅ Secrets detection using regex + ML-based scanning
- ⚠️ User education: never share raw agent outputs
- ✅ Audit logs allow post-incident analysis

**Residual Risk**: Medium (depends on auditor effectiveness)

---

### Scenario 4: Policy Engine Compromise

**Threat Actor**: TA-2 (External Attacker)  
**Attack Vector**:
1. Exploits vulnerability in OPA or Cerbos
2. Modifies policies to allow all actions
3. Agents gain unrestricted access

**Impact**: Critical - Complete control plane compromise

**Mitigations**:
- ✅ OPA/Cerbos containers isolated, no external access
- ✅ Policies versioned in Git with code review
- ✅ Immutable policy bundles loaded at startup
- ✅ Monitoring for policy changes (alert on unexpected updates)
- ⚠️ Regular security updates for OPA/Cerbos

**Residual Risk**: Low

---

### Scenario 5: Audit Log Tampering

**Threat Actor**: TA-1 or TA-2  
**Attack Vector**:
1. Gains access to Postgres or MinIO
2. Modifies or deletes audit logs
3. Hides malicious activity

**Impact**: High - Loss of forensic evidence, compliance failure

**Mitigations**:
- ✅ Audit service uses append-only table with triggers preventing updates/deletes
- ✅ Cryptographic hashing of each log entry
- ✅ Periodic export to immutable storage (WORM bucket or write-once NFS)
- ✅ Postgres restricted to Audit Service only (no direct agent access)
- ⚠️ Regular integrity checks (verify hashes)

**Residual Risk**: Low

---

### Scenario 6: OIDC/Auth Bypass

**Threat Actor**: TA-2 (External Attacker)  
**Attack Vector**:
1. Exploits vulnerability in Authentik/Keycloak
2. Forges JWT tokens
3. Gains admin access to SentinelForge API

**Impact**: Critical - Full system control

**Mitigations**:
- ✅ Authentik/Keycloak on separate container, hardened
- ✅ Short-lived JWT tokens (15 min)
- ✅ Token validation on every API request
- ✅ Rate limiting on auth endpoints
- ⚠️ Regular security updates
- ⚠️ Enable MFA for all users

**Residual Risk**: Medium

---

### Scenario 7: Supply Chain Attack (Malicious Package)

**Threat Actor**: TA-4 (Supply Chain)  
**Attack Vector**:
1. Malicious Python package installed via `pip`
2. Package exfiltrates secrets or opens backdoor
3. Attacker gains persistent access

**Impact**: Critical - Complete compromise

**Mitigations**:
- ✅ Dependency pinning with hash verification
- ✅ Renovate/Dependabot for automated updates
- ⚠️ Use `pip-audit` / `safety` in CI
- ⚠️ Trivy/Grype scans on Docker images
- ⚠️ Private PyPI mirror with vetted packages (future)

**Residual Risk**: Medium

---

### Scenario 8: Model Poisoning / Jailbreak

**Threat Actor**: TA-2 (External Attacker) via prompt injection  
**Attack Vector**:
1. User provides malicious input that tricks agent
2. Agent generates harmful output or actions
3. Bypasses guardrails via jailbreak techniques

**Impact**: Medium - Unwanted actions, reputation damage

**Mitigations**:
- ✅ Input sanitization on all user-provided prompts
- ✅ System prompts emphasize security policies
- ✅ Auditor service as second opinion
- ✅ Human-in-the-loop for high-risk actions
- ⚠️ Ongoing research into robust prompt engineering

**Residual Risk**: Medium (evolving threat)

---

## Trust Boundaries

```
┌──────────────────────────────────────────────┐
│           TRUSTED ZONE                       │
│  Control Plane, Policy Engine, Audit         │
│  (High privilege, enforces security)         │
└──────────────────┬───────────────────────────┘
                   │
         ┌─────────▼─────────┐
         │   Tool Gateway    │  ← Trust boundary enforcer
         └─────────┬─────────┘
                   │
┌──────────────────▼───────────────────────────┐
│          UNTRUSTED ZONE                      │
│  Agent Runtime (Assume compromised)          │
│  Read-only FS, network isolation             │
└──────────────────────────────────────────────┘
```

**Key Principle**: Never trust agent outputs. Always validate and audit.

## Compliance Considerations

- **GDPR**: Audit logs contain user actions; ensure data retention policies and right-to-erasure mechanisms
- **SOC 2**: Immutable logs, access controls, and observability support compliance
- **Homelab Context**: No customer data initially, but good practices for future commercial use

## Incident Response Plan

### Detection
- Grafana alerts on anomalies: high tool call denial rate, unusual API usage, failed auth attempts
- Daily review of audit log summary dashboard

### Containment
1. Identify compromised component via logs and traces
2. `docker-compose stop <service>` or `kubectl delete pod`
3. Isolate network segment if needed

### Eradication
1. Review audit logs to determine scope
2. Rotate all secrets (API keys, DB passwords)
3. Rebuild containers from known-good images

### Recovery
1. Restore from last known-good Postgres backup
2. Verify audit log integrity (check hashes)
3. Gradually re-enable services with enhanced monitoring

### Lessons Learned
- Document incident in `docs/incidents/`
- Update policies or architecture to prevent recurrence
- Share anonymized findings with community (if appropriate)

## Security Testing Plan

### Phase 1 (Pre-Launch)
- [ ] Threat model review (this document)
- [ ] Manual penetration test: attempt sandbox escape
- [ ] Policy engine fuzzing (malformed requests)
- [ ] Secret scanning on all commits (pre-commit hook)

### Phase 2 (Post-Launch)
- [ ] Quarterly third-party security audit
- [ ] Red team exercise: simulate compromised agent
- [ ] Dependency audits (weekly `pip-audit`)
- [ ] Container image scans (Trivy in CI)

### Continuous
- Automated secret scanning (TruffleHog, GitGuardian)
- SAST on all Python code (Bandit, Semgrep)
- Dependabot alerts

## Open Questions

1. **Offline LLMs**: If using only local Ollama, does that reduce risk? (Yes, but model quality trade-off)
2. **Multi-tenancy**: Future feature; requires namespace isolation and per-user policy enforcement
3. **Hardware attacks**: Homelab physical security assumed; document in deployment guide

## Threat Model Maintenance

- **Owner**: Security lead (currently: project maintainer)
- **Review Cadence**: Quarterly or after major architecture changes
- **Update Trigger**: New threats identified, incident, dependency vulnerability

---

**Last Updated**: 2026-03-06  
**Next Review**: 2026-06-06
