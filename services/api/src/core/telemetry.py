"""OpenTelemetry configuration."""

import structlog
from src.core.config import settings

logger = structlog.get_logger()


def setup_telemetry():
    """Configure OpenTelemetry tracing."""
    if not settings.OTEL_ENABLED:
        logger.info("Telemetry disabled, skipping setup")
        return

    try:
        from opentelemetry import trace
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
        from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
        from opentelemetry.instrumentation.redis import RedisInstrumentor

        resource = Resource.create({
            "service.name": "sentinelforge-api",
            "service.version": settings.VERSION,
            "deployment.environment": "homelab",
        })

        provider = TracerProvider(resource=resource)

        otlp_exporter = OTLPSpanExporter(
            endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
            insecure=True,
        )

        provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
        trace.set_tracer_provider(provider)

        FastAPIInstrumentor.instrument()
        SQLAlchemyInstrumentor().instrument()
        RedisInstrumentor().instrument()

        logger.info("Telemetry initialized", endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT)
    except Exception as e:
        logger.warning("Telemetry setup failed, continuing without it", error=str(e))
