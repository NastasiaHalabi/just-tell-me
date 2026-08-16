from datetime import timedelta

from app.ai.compose import compose_chat_message
from app.ai.models import PlanRequest
from app.ai.planner import plan_utterance
from app.ai.time_parser import extract_datetime, parse_now

NOW = parse_now("2026-08-16T22:00:00+03:00", "Asia/Beirut")


def test_after_30_seconds() -> None:
    dt = extract_datetime("send a message for nour after 30 seconds", NOW)
    assert dt is not None
    assert dt - NOW == timedelta(seconds=30)


def test_hi_message_is_rephrased() -> None:
    assert compose_chat_message("send a hi message for nour", "Nour") == "Hi Nour"


def test_delayed_whatsapp_plan() -> None:
    plan = plan_utterance(
        PlanRequest(
            text="send a message for nour after 30 seconds",
            client_local_datetime="2026-08-16T22:00:00+03:00",
            timezone="Asia/Beirut",
        )
    )
    action = plan.actions[0]
    assert action.type.value == "PREPARE_WHATSAPP"
    assert action.recipient is not None
    assert action.recipient.display_name == "Nour"
    assert action.message == "Hi Nour"
    assert action.scheduled_for is not None
    assert "send a message" not in (action.message or "").lower()


def test_hi_whatsapp_plan_not_raw_command() -> None:
    plan = plan_utterance(
        PlanRequest(
            text="send a hi message for nour",
            client_local_datetime="2026-08-16T22:00:00+03:00",
            timezone="Asia/Beirut",
        )
    )
    action = plan.actions[0]
    assert action.type.value == "PREPARE_WHATSAPP"
    assert action.message == "Hi Nour"
