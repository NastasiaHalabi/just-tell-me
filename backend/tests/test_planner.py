from __future__ import annotations

import json
from pathlib import Path

import pytest

from app.ai.models import PlanRequest
from app.ai.planner import plan_utterance
from app.ai.schemas import validate_plan
from tests.golden_source import all_cases

GOLDEN_PATH = Path(__file__).resolve().parents[2] / "shared" / "golden" / "utterances.json"


@pytest.fixture(scope="module")
def cases() -> list[dict]:
    if GOLDEN_PATH.exists():
        return json.loads(GOLDEN_PATH.read_text(encoding="utf-8"))
    return all_cases()


@pytest.mark.parametrize("case", all_cases(), ids=lambda c: c["id"])
def test_golden_action_types(case: dict) -> None:
    request = PlanRequest(
        text=case["text"],
        client_local_datetime="2026-08-16T22:00:00+03:00",
        timezone="Asia/Beirut",
        locale_hints=["en", "ar-LB"],
    )
    plan = plan_utterance(request)
    payload = validate_plan(plan)
    got = [action["type"] for action in payload["actions"]]
    assert got == case["expected_types"], f"{case['id']}: {case['text']}\n got={got}"


def test_whatsapp_is_handoff_not_sent() -> None:
    plan = plan_utterance(
        PlanRequest(
            text="Ask Nour if she wants a session at 3",
            client_local_datetime="2026-08-16T22:00:00+03:00",
            timezone="Asia/Beirut",
        )
    )
    action = plan.actions[0]
    assert action.type.value == "PREPARE_WHATSAPP"
    assert action.confirmation.value == "handoff"
    assert action.status.value == "planned"


def test_memory_candidate_phone_goes_on_whatsapp_recipient() -> None:
    plan = plan_utterance(
        PlanRequest(
            text="eb3at la Maya 3al whatsapp",
            client_local_datetime="2026-08-16T22:00:00+03:00",
            timezone="Asia/Beirut",
            context={
                "candidate_contacts": [
                    {
                        "contact_id": "memory:maya",
                        "display_name": "Maya Khoury",
                        "phone": "+96170111222",
                        "aliases": ["Maya", "mama"],
                    }
                ]
            },
        )
    )
    action = plan.actions[0]
    assert action.type.value == "PREPARE_WHATSAPP"
    assert action.recipient is not None
    assert action.recipient.phone == "+96170111222"
    assert action.recipient.display_name == "Maya Khoury"


def test_email_send_requires_confirm() -> None:
    plan = plan_utterance(
        PlanRequest(
            text="Tomorrow email Karim that the report is done",
            client_local_datetime="2026-08-16T22:00:00+03:00",
            timezone="Asia/Beirut",
        )
    )
    assert plan.actions[0].type.value == "SEND_EMAIL"
    assert plan.actions[0].confirmation.value == "confirm"


def test_ambiguous_person_clarification() -> None:
    request = PlanRequest(
        text="Call Maya",
        client_local_datetime="2026-08-16T22:00:00+03:00",
        timezone="Asia/Beirut",
        context={
            "candidate_contacts": [
                {"contact_id": "1", "display_name": "Maya Piano"},
                {"contact_id": "2", "display_name": "Maya Neighbor"},
            ]
        },
    )
    plan = plan_utterance(request)
    assert plan.needs_clarification is True
    assert plan.clarification is not None
    assert plan.clarification.reason == "ambiguous_person"


def test_unknown_action_type_rejected_by_schema() -> None:
    from app.ai.models import Action, ActionPlan, ActionStatus, Confirmation

    with pytest.raises(Exception):
        Action(
            id="a1",
            type="HACK_THE_PLANET",  # type: ignore[arg-type]
            status=ActionStatus.PLANNED,
            confirmation=Confirmation.AUTO,
        )
