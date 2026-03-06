"""Tool management endpoints (placeholder for Phase 2)."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def list_tools():
    """List available tools."""
    return {"tools": [], "message": "Coming in Phase 2"}


@router.get("/{tool_id}")
async def get_tool(tool_id: str):
    """Get tool details."""
    return {"tool_id": tool_id, "message": "Coming in Phase 2"}
