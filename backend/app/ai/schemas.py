from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from jsonschema import Draft202012Validator

from app.ai.models import ActionPlan

SCHEMA_PATH = (
    Path(__file__).resolve().parents[3] / "shared" / "schemas" / "action_plan.schema.json"
)


def load_schema() -> dict[str, Any]:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


_VALIDATOR = Draft202012Validator(load_schema())


class InvalidActionPlanError(ValueError):
    pass


def validate_plan(plan: ActionPlan | dict[str, Any]) -> dict[str, Any]:
    payload = plan.model_dump(mode="json") if isinstance(plan, ActionPlan) else plan
    errors = sorted(_VALIDATOR.iter_errors(payload), key=lambda e: list(e.path))
    if errors:
        messages = [f"{'/'.join(str(p) for p in err.path)}: {err.message}" for err in errors]
        raise InvalidActionPlanError("; ".join(messages))
    return payload
