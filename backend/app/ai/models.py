from __future__ import annotations

from enum import Enum
from typing import Any, Optional

from pydantic import BaseModel, Field


class ActionType(str, Enum):
    CREATE_REMINDER = "CREATE_REMINDER"
    CREATE_TASK = "CREATE_TASK"
    COMPLETE_TASK = "COMPLETE_TASK"
    CREATE_CALENDAR_EVENT = "CREATE_CALENDAR_EVENT"
    UPDATE_CALENDAR_EVENT = "UPDATE_CALENDAR_EVENT"
    DELETE_CALENDAR_EVENT = "DELETE_CALENDAR_EVENT"
    QUERY_CALENDAR = "QUERY_CALENDAR"
    DRAFT_EMAIL = "DRAFT_EMAIL"
    SEND_EMAIL = "SEND_EMAIL"
    SEARCH_EMAIL = "SEARCH_EMAIL"
    CALL_CONTACT = "CALL_CONTACT"
    PREPARE_SMS = "PREPARE_SMS"
    PREPARE_TELEGRAM = "PREPARE_TELEGRAM"
    PREPARE_WHATSAPP = "PREPARE_WHATSAPP"
    SHARE_MEDIA = "SHARE_MEDIA"
    SAVE_NOTE = "SAVE_NOTE"
    QUERY_TASKS = "QUERY_TASKS"
    QUERY_MEMORY = "QUERY_MEMORY"


class ActionStatus(str, Enum):
    PLANNED = "planned"
    AWAITING_CONFIRMATION = "awaiting_confirmation"
    EXECUTING = "executing"
    COMPLETED = "completed"
    HANDED_OFF = "handed_off"
    SCHEDULED = "scheduled"
    FAILED = "failed"
    UNSUPPORTED = "unsupported"
    CANCELLED = "cancelled"


class Confirmation(str, Enum):
    AUTO = "auto"
    CONFIRM = "confirm"
    HANDOFF = "handoff"


class Recipient(BaseModel):
    contact_id: Optional[str] = None
    display_name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None


class Clarification(BaseModel):
    prompt: str
    reason: str
    options: list[str] = Field(default_factory=list)


class Action(BaseModel):
    id: str
    type: ActionType
    status: ActionStatus = ActionStatus.PLANNED
    confirmation: Confirmation
    title: Optional[str] = None
    notes: Optional[str] = None
    recipient: Optional[Recipient] = None
    message: Optional[str] = None
    subject: Optional[str] = None
    start_at: Optional[str] = None
    end_at: Optional[str] = None
    scheduled_for: Optional[str] = None
    remind_at: Optional[str] = None
    query: Optional[str] = None
    media_refs: list[str] = Field(default_factory=list)
    depends_on: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)


class ActionPlan(BaseModel):
    schema_version: str = "1.0"
    plan_id: str
    original_text: str
    summary: str
    actions: list[Action]
    needs_clarification: bool = False
    clarification: Optional[Clarification] = None
    confidence: float = 0.8


class CandidateContact(BaseModel):
    contact_id: str
    display_name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    aliases: list[str] = Field(default_factory=list)


class RelevantEvent(BaseModel):
    event_id: str
    title: str
    start_at: str
    end_at: Optional[str] = None


class PlanContext(BaseModel):
    candidate_contacts: list[CandidateContact] = Field(default_factory=list)
    relevant_events: list[RelevantEvent] = Field(default_factory=list)


class PlanRequest(BaseModel):
    text: str
    client_local_datetime: str
    timezone: str = "Asia/Beirut"
    locale_hints: list[str] = Field(default_factory=lambda: ["en", "ar-LB"])
    context: PlanContext = Field(default_factory=PlanContext)
