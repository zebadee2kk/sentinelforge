"""SentinelForge API - Main application entry point."""

import structlog
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator

from src.core.config import settings
from src.core.telemetry import setup_telemetry
from src.api.v1 import health, auth, runs, agents, tools
from src.db.session import engine
from src.db.base import Base

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    logger.info("Starting SentinelForge API", version=settings.VERSION)
    
    # Initialize telemetry
    setup_telemetry()
    
    # Create database tables (in production, use Alembic migrations)
    # async with engine.begin() as conn:
    #     await conn.run_sync(Base.metadata.create_all)
    
    logger.info("API started successfully")
    yield
    
    logger.info("Shutting down SentinelForge API")


app = FastAPI(
    title="SentinelForge API",
    description="Secure homelab platform for autonomous AI agents",
    version=settings.VERSION,
    lifespan=lifespan,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

# API Routes
app.include_router(health.router, tags=["health"])
app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(runs.router, prefix="/api/v1/runs", tags=["runs"])
app.include_router(agents.router, prefix="/api/v1/agents", tags=["agents"])
app.include_router(tools.router, prefix="/api/v1/tools", tags=["tools"])


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "service": "SentinelForge API",
        "version": settings.VERSION,
        "status": "operational",
    }
