"""Application configuration."""

from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings."""
    
    # Application
    VERSION: str = "0.1.0"
    DEBUG: bool = False
    ALLOWED_ORIGINS: List[str] = ["*"]
    
    # Database
    DATABASE_URL: str
    
    # Redis
    REDIS_URL: str
    
    # MinIO
    MINIO_ENDPOINT: str
    MINIO_ACCESS_KEY: str
    MINIO_SECRET_KEY: str
    MINIO_BUCKET: str = "sentinelforge-audit"
    MINIO_SECURE: bool = False
    
    # Authentication
    AUTHENTIK_URL: str
    AUTHENTIK_TOKEN: str
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    
    # Observability
    OTEL_EXPORTER_OTLP_ENDPOINT: str = "http://tempo:4317"
    LOG_LEVEL: str = "INFO"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
