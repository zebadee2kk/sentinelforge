# OPA Policy Examples

This document shows example Open Policy Agent (OPA) policies for controlling SentinelForge tool access.

These policies are conceptual and should be adapted to your actual data model and deployment.

## Data Model

Assume an input structure like:

```json
{
  "agent": {
    "id": "agent-123",
    "role": "researcher",
    "trust_level": "sandbox"
  },
  "user": {
    "id": "user-456",
    "roles": ["developer", "viewer"]
  },
  "tool": {
    "name": "github_read",
    "permission": "read"
  },
  "resource": {
    "type": "repository",
    "name": "zebadee2kk/sentinelforge"
  },
  "context": {
    "environment": "homelab",
    "ip": "192.168.10.50"
  }
}
```

## tools.rego

```rego
package sentinelforge.tools

default allow = false

# Helper: agent trust levels
is_sandbox_agent(agent) {
  agent.trust_level == "sandbox"
}

is_restricted_agent(agent) {
  agent.trust_level == "restricted"
}

is_privileged_agent(agent) {
  agent.trust_level == "privileged"
}

# Helper: tool permission classification
is_readonly_tool(tool) {
  tool.permission == "read"
}

is_write_tool(tool) {
  tool.permission == "write"
}

is_admin_tool(tool) {
  tool.permission == "admin"
}

# Rule: sandbox agents may only use read-only tools
allow {
  is_sandbox_agent(input.agent)
  is_readonly_tool(input.tool)
}

# Rule: restricted agents may use read-only tools and a small set of write tools
allow {
  is_restricted_agent(input.agent)
  is_readonly_tool(input.tool)
}

allow {
  is_restricted_agent(input.agent)
  is_write_tool(input.tool)
  input.tool.name == "github_create_pr"
}

# Rule: privileged agents may use all tools except explicitly banned ones
allow {
  is_privileged_agent(input.agent)
  not banned_tool
}

banned_tool {
  input.tool.name == "delete_database"
}

banned_tool {
  input.tool.name == "system_shutdown"
}

# Optional: environment-specific restrictions
allow {
  is_sandbox_agent(input.agent)
  is_readonly_tool(input.tool)
  input.context.environment == "homelab"
}
```

## agents.rego

```rego
package sentinelforge.agents

default allow_run = false

# Basic user role mapping
user_is_admin {
  some r
  r := input.user.roles[_]
  r == "admin"
}

user_is_security {
  some r
  r := input.user.roles[_]
  r == "security"
}

user_is_developer {
  some r
  r := input.user.roles[_]
  r == "developer"
}

# Rule: only admins and security can run privileged agents
allow_run {
  input.agent.trust_level == "privileged"
  user_is_admin
}

allow_run {
  input.agent.trust_level == "privileged"
  user_is_security
}

# Rule: developers and admins can run restricted agents
allow_run {
  input.agent.trust_level == "restricted"
  user_is_developer
}

allow_run {
  input.agent.trust_level == "restricted"
  user_is_admin
}

# Rule: anyone with a valid session can run sandbox agents
allow_run {
  input.agent.trust_level == "sandbox"
  input.user.id != ""
}
```

## Usage Pattern

At the SentinelForge Tool Gateway:

1. Construct an input document from the incoming request (user, agent, tool, resource, context).
2. Query OPA for a policy decision:

```bash
curl -s -X POST \
  http://opa:8181/v1/data/sentinelforge/tools/allow \
  -d '{"input": { ... }}'
```

3. If OPA returns `true`, proceed with the tool call. If `false`, deny and log the attempt.

Similarly, when starting a run, call `sentinelforge/agents/allow_run` to check whether the current user is allowed to run the selected agent.

## Extending Policies

You can extend these policies to include:

- Time-based restrictions (e.g., no destructive tools outside business hours).
- IP-based controls (e.g., block high-risk tools from untrusted networks).
- Environment-specific rules (e.g., stricter policies in production than homelab).

These examples are provided as a starting point and should be adapted to your organization’s risk appetite and compliance requirements.
