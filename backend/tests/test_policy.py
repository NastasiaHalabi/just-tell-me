from app.ai.models import ActionType, Confirmation
from app.core.policy import apply_policy_floor


def test_policy_cannot_lower_email_send_to_auto() -> None:
    assert apply_policy_floor(ActionType.SEND_EMAIL, Confirmation.AUTO) == Confirmation.CONFIRM


def test_policy_keeps_higher_handoff() -> None:
    assert apply_policy_floor(ActionType.CREATE_REMINDER, Confirmation.HANDOFF) == Confirmation.HANDOFF


def test_whatsapp_floor_is_handoff() -> None:
    assert apply_policy_floor(ActionType.PREPARE_WHATSAPP, Confirmation.AUTO) == Confirmation.HANDOFF
