"""Confirmation policy is rules-based. The planner cannot lower required confirmation."""

from __future__ import annotations

from enum import Enum

from app.ai.models import ActionType, Confirmation


class PolicyFloor(str, Enum):
    AUTO = "auto"
    CONFIRM = "confirm"
    HANDOFF = "handoff"


DEFAULT_FLOORS: dict[ActionType, Confirmation] = {
    ActionType.CREATE_REMINDER: Confirmation.AUTO,
    ActionType.CREATE_TASK: Confirmation.AUTO,
    ActionType.COMPLETE_TASK: Confirmation.AUTO,
    ActionType.CREATE_CALENDAR_EVENT: Confirmation.AUTO,
    ActionType.UPDATE_CALENDAR_EVENT: Confirmation.CONFIRM,
    ActionType.DELETE_CALENDAR_EVENT: Confirmation.CONFIRM,
    ActionType.QUERY_CALENDAR: Confirmation.AUTO,
    ActionType.DRAFT_EMAIL: Confirmation.AUTO,
    ActionType.SEND_EMAIL: Confirmation.CONFIRM,
    ActionType.SEARCH_EMAIL: Confirmation.AUTO,
    ActionType.CALL_CONTACT: Confirmation.CONFIRM,
    ActionType.PREPARE_SMS: Confirmation.HANDOFF,
    ActionType.PREPARE_WHATSAPP: Confirmation.HANDOFF,
    ActionType.PREPARE_TELEGRAM: Confirmation.HANDOFF,
    ActionType.SHARE_MEDIA: Confirmation.CONFIRM,
    ActionType.SAVE_NOTE: Confirmation.AUTO,
    ActionType.QUERY_TASKS: Confirmation.AUTO,
    ActionType.QUERY_MEMORY: Confirmation.AUTO,
}

_RANK = {
    Confirmation.AUTO: 0,
    Confirmation.CONFIRM: 1,
    Confirmation.HANDOFF: 2,
}


def apply_policy_floor(action_type: ActionType, proposed: Confirmation) -> Confirmation:
    """Raise confirmation to at least the floor. Never reduce it."""
    floor = DEFAULT_FLOORS[action_type]
    if _RANK[proposed] >= _RANK[floor]:
        return proposed
    return floor
