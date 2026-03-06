"""Agent management endpoints (placeholder for Phase 2)."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_agents():
    """List configured agents."""
    return {"agents": [], "message": "Coming in Phase 2"}


@router.post("/")
async def create_agent():
    """Create a new agent."""
    return {"message": "Agent creation coming in Phase 2"}


@router.get("/{agent_id}")
async def get_agent(agent_id: str):
    """Get agent details."""
    return {"agent_id": agent_id, "message": "Coming in Phase 2"}
