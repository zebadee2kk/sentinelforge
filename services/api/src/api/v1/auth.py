"""Authentication endpoints (placeholder for Phase 1)."""

from fastapi import APIRouter

router = APIRouter()


@router.post("/token")
async def login():
    """OAuth token endpoint (placeholder)."""
    return {"message": "Auth integration with Authentik coming in Phase 1"}


@router.get("/me")
async def get_current_user():
    """Get current user (placeholder)."""
    return {"message": "User profile coming in Phase 1"}
