"""Redis connection management."""

from redis.asyncio import Redis
from src.core.config import settings


async def get_redis() -> Redis:
    """Dependency for getting Redis connection."""
    redis = Redis.from_url(
        settings.REDIS_URL,
        encoding="utf-8",
        decode_responses=True,
    )
    try:
        yield redis
    finally:
        await redis.close()
