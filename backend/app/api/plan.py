from fastapi import APIRouter, HTTPException

from app.ai.models import ActionPlan, PlanRequest
from app.ai.planner import plan_utterance
from app.ai.schemas import InvalidActionPlanError, validate_plan

router = APIRouter()


@router.post("/v1/plan", response_model=ActionPlan)
def create_plan(request: PlanRequest) -> ActionPlan:
    if not request.text.strip():
        raise HTTPException(status_code=422, detail="text is required")
    plan = plan_utterance(request)
    try:
        validate_plan(plan)
    except InvalidActionPlanError as exc:
        raise HTTPException(status_code=500, detail=f"planner produced invalid ActionPlan: {exc}") from exc
    return plan
