# Observability Design

This document describes how SentinelForge instruments and monitors AI agents, tools, and infrastructure using OpenTelemetry and the Grafana stack.

## Goals

- **End-to-end traces** for each agent run, including LLM calls and tool invocations.[web:83][web:89]
- **Metrics** for performance, reliability, and cost (latency, errors, token usage).[web:83][web:89]
- **Structured logs** that correlate with traces and runs (via `trace_id` and `run_id`).[web:83][web:89]
- **Dashboards and alerts** to detect anomalies and regressions quickly.

## Telemetry Stack

SentinelForge uses:

- **OpenTelemetry SDKs** in all Python services for tracing.
- **Tempo** as the trace backend.
- **Prometheus** for metrics.
- **Loki** for logs.
- **Grafana** as a unified UI.[web:83][web:86][web:89]

## Trace Model

Each agent run becomes a root span, with nested spans for major steps:

- `run.start` — request received by API.
- `plan` — agent planning phase.
- `llm.call` — each LLM call (actor and auditor models).
- `tool.call` — each tool invocation via Tool Gateway.
- `policy.decision` — calls to OPA/Cerbos.
- `audit.log` — writes to the audit service.
- `run.complete` — finalization and response.

Example (Python):

```python
from opentelemetry import trace

tracer = trace.get_tracer("sentinelforge.api")

async def run_agent(request: RunRequest):
    with tracer.start_as_current_span("run") as span:
        span.set_attribute("run.id", request.run_id)
        span.set_attribute("agent.id", request.agent_id)
        span.set_attribute("user.id", request.user_id)
        # ... call orchestrator, tools, etc.
```

Service names:

- `sentinelforge-api`
- `sentinelforge-orchestrator`
- `sentinelforge-tool-gateway`
- `sentinelforge-auditor`
- `sentinelforge-model-router`

## Metrics

Key metrics (Prometheus):

### API

- `sentinelforge_api_requests_total{path,method,status}`
- `sentinelforge_api_request_duration_seconds_bucket{path,method}`

### Runs

- `sentinelforge_runs_total{status,agent_id}`
- `sentinelforge_run_duration_seconds_bucket{agent_id}`

### Tools

- `sentinelforge_tool_calls_total{tool_name,agent_id,decision}`
- `sentinelforge_tool_call_duration_seconds_bucket{tool_name}`

### Models

- `sentinelforge_llm_calls_total{model,provider}`
- `sentinelforge_llm_tokens_total{model,provider,type="prompt|completion|total"}`
- `sentinelforge_llm_latency_seconds_bucket{model,provider}`

These can be exposed via `prometheus-client` or `prometheus-fastapi-instrumentator` in the API and via OTEL metrics in other services.[web:83][web:86]

## Logs

All services log structured JSON to stdout, collected by Loki:

- Fields:
  - `timestamp`
  - `level`
  - `service`
  - `trace_id`
  - `span_id`
  - `run_id`
  - `agent_id`
  - `tool_name`
  - `event` (e.g., `tool_allowed`, `tool_denied`, `auditor_blocked`)

Example (Python with structlog):

```python
logger.info(
    "tool_call_decision",
    run_id=run_id,
    agent_id=agent_id,
    tool_name=tool_name,
    decision="deny",
    reason="policy",
    trace_id=current_trace_id,
)
```

Grafana can link traces and logs using `trace_id` so you can pivot between them easily.[web:83][web:89]

## Dashboards

Recommended Grafana dashboards:

### 1. Agent Overview

- Runs per minute by status.
- Average run duration per agent.
- Top failing agents (by error count).
- Histogram of tokens used per run.

### 2. Tool Usage & Policy

- Tool calls by tool name and decision (`allow`, `deny`).
- Denied calls by reason (policy, rate limit, error).
- Heatmap of tools vs agents.

### 3. LLM Performance & Cost

- LLM calls per provider/model.
- Tokens per provider/model.
- Approximate cost per day (if cost per 1k tokens is configured).
- Latency distribution per model.

### 4. Infrastructure Health

- CPU, memory, and disk for Postgres, MinIO, Redis.
- API latency and error rates.
- Tempo and Loki ingestion health.

## Alerts

Example alerting rules:

- High error rate:
  - `sentinelforge_api_requests_total{status=~"5.."}` exceeds threshold.
- High policy denials:
  - Spike in `sentinelforge_tool_calls_total{decision="deny"}`.
- Stuck runs:
  - Runs with duration above a threshold.
- Backend health:
  - Tempo/Loki/Prometheus not scraping or ingesting data.

Alerts can be sent via email, Slack, or other channels supported by Grafana.

## OTEL Configuration

Each service uses OTEL exporters configured to send traces to Tempo:

- Endpoint: `OTEL_EXPORTER_OTLP_ENDPOINT=http://tempo:4317`
- Protocol: gRPC

Python example:

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource

resource = Resource.create({
    "service.name": "sentinelforge-api",
    "service.version": "0.1.0",
    "deployment.environment": "homelab",
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo:4317", insecure=True))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
```

## Next Steps

- Implement OTEL spans in all core services.
- Expose Prometheus metrics for runs, tools, and models.
- Build initial Grafana dashboards under the `SentinelForge` folder.
- Add alerting rules for key failure modes.

As the platform matures, consider adding anomaly detection or ML-based monitoring on top of this telemetry.
