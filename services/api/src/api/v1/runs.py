"""Run management endpoints (placeholder for Phase 2)."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_runs():
    """List agent runs."""
    return {"runs": [], "message": "Coming in Phase 2"}


@router.post("/")
async def create_run():
    """Create a new agent run."""
    return {"message": "Run creation coming in Phase 2"}


@router.get("/{run_id}")
async def get_run(run_id: str):
    """Get run details."""
    return {"run_id": run_id, "message": "Coming in Phase 2"}
