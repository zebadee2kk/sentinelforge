"""OpenTelemetry configuration."""

import structlog
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor

from src.core.config import settings

logger = structlog.get_logger()


def setup_telemetry():
    """Configure OpenTelemetry tracing."""
    resource = Resource.create({
        "service.name": "sentinelforge-api",
        "service.version": settings.VERSION,
        "deployment.environment": "homelab",
    })
    
    provider = TracerProvider(resource=resource)
    
    # OTLP exporter to Tempo
    otlp_exporter = OTLPSpanExporter(
        endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
        insecure=True,
    )
    
    provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
    trace.set_tracer_provider(provider)
    
    # Auto-instrumentation
    FastAPIInstrumentor.instrument()
    SQLAlchemyInstrumentor().instrument()
    RedisInstrumentor().instrument()
    
    logger.info("Telemetry initialized", endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT)
