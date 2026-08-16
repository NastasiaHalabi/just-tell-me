"""Deterministic planner: interpret utterances into a validated ActionPlan.

The LLM never executes. This module is the default interpreter so Lebanese,
Arabizi, and English commands work without a vendor key. An optional LLM
adapter can replace interpretation later, still returning this schema.
"""

from __future__ import annotations

import re
import uuid
from datetime import timedelta
from typing import Optional

from app.ai.models import (
    Action,
    ActionPlan,
    ActionStatus,
    ActionType,
    CandidateContact,
    Clarification,
    Confirmation,
    PlanRequest,
    Recipient,
)
from app.ai.compose import compose_chat_message
from app.ai.time_parser import extract_datetime, parse_now
from app.core.policy import apply_policy_floor


CONNECTORS = re.compile(
    r"(?:,\s+|\s+and then\s+|\s+\band\b\s+|\s+then\s+|\s+\bw\b\s+|\s+و(?=حط|ابعت|ذكر|دق|اسأل|ضيف)|\s+kameen\s+|\s+kaman\s+)",
    re.IGNORECASE,
)

NAME_RE = re.compile(
    r"\b(?:to|with|for|ask|call|email|tell|la|li|لـ|ل)\s+(?!a\b|an\b|the\b|me\b)([A-Za-z]{2,}|[\u0600-\u06FF]{2,})",
    re.UNICODE | re.IGNORECASE,
)

_NAME_STOP = {
    "me",
    "my",
    "the",
    "a",
    "an",
    "if",
    "she",
    "he",
    "them",
    "session",
    "meeting",
    "report",
    "photo",
    "email",
    "for",
    "to",
    "hi",
    "hello",
    "hey",
    "message",
    "send",
    "after",
    "before",
    "seconds",
    "minutes",
    "hours",
}

KNOWN_CHANNELS = ("whatsapp", "telegram", "sms", "email", "gmail")


def _split_clauses(text: str) -> list[str]:
    parts = [p.strip(" .،,") for p in CONNECTORS.split(text) if p.strip(" .،,")]
    return parts or [text.strip()]


def _match_contact(name: str, candidates: list[CandidateContact]) -> tuple[Optional[CandidateContact], list[CandidateContact]]:
    needle = name.lower()
    matches = []
    for contact in candidates:
        hay = " ".join([contact.display_name, *contact.aliases]).lower()
        if needle in hay or hay in needle:
            matches.append(contact)
    if len(matches) == 1:
        return matches[0], matches
    return None, matches


def _extract_name(clause: str, original: str) -> Optional[str]:
    m = NAME_RE.search(clause)
    if m:
        token = m.group(1)
        if token.lower() not in _NAME_STOP:
            return token.title() if token.isascii() else token
    m = re.search(r"\b([A-Z][a-z]{2,})\b", clause)
    if m:
        return m.group(1)
    # Arabic names after ل
    m = re.search(r"ل(?:ـ)?\s*([\u0600-\u06FF]{2,})", clause)
    if m:
        return m.group(1)
    return None


def _classify(clause: str) -> ActionType:
    lower = clause.lower()

    if re.search(r"what am i forgetting|شو نسيت|what tasks|المهام", lower):
        return ActionType.QUERY_TASKS
    if re.search(r"\bwho is\b|مين |ذاكرة|\balias\b", lower):
        return ActionType.QUERY_MEMORY
    if re.search(r"shu 3ande|shu 3andi|شو عندي|what('s| is) on|my schedule|what's tomorrow", lower):
        return ActionType.QUERY_CALENDAR
    if re.search(r"search (my )?email|find email|دور عالايميل", lower):
        return ActionType.SEARCH_EMAIL
    if re.search(r"last photo|\bphoto\b|share (this |the )?photo|الصورة", lower):
        return ActionType.SHARE_MEDIA
    if re.search(r"\btelegram\b|تلغرام", lower):
        return ActionType.PREPARE_TELEGRAM
    if re.search(r"\bsms\b|text message|\btext\b [A-Z]|رسالة نصية", clause, re.I):
        return ActionType.PREPARE_SMS
    if re.search(r"remind|zakirne|zakerni|ذكرني", lower):
        return ActionType.CREATE_REMINDER
    if re.search(r"complete task|mark .*done|خلصت", lower):
        return ActionType.COMPLETE_TASK
    if re.search(r"\btask\b|\btodo\b|مهمة", lower):
        return ActionType.CREATE_TASK
    if re.search(r"\bcall\b|\bde2\b|دق", lower):
        return ActionType.CALL_CONTACT
    if re.search(r"move |reschedule|غيّر|غير الموعد|postpone|أجل", lower):
        return ActionType.UPDATE_CALENDAR_EVENT
    if re.search(r"cancel (the )?meeting|delete .*\bevent\b|cancel event|الغي|امسح", lower):
        return ActionType.DELETE_CALENDAR_EVENT
    if re.search(r"save (a )?note|write down|سجل", lower):
        return ActionType.SAVE_NOTE
    if re.search(r"remember that", lower):
        return ActionType.QUERY_MEMORY
    if re.search(r"draft email|draft (an )?email|اكتب ايميل|اكتب إيميل", lower):
        return ActionType.DRAFT_EMAIL
    if re.search(r"\bemail\b|ايميل|إيميل|gmail", lower):
        return ActionType.SEND_EMAIL
    if re.search(r"\bwhatsapp\b|واتس|\bask\b|اسأل|اسال|\beb3at\b|ابعت|\bmessage\b|\btell\b", lower):
        return ActionType.PREPARE_WHATSAPP
    if re.search(r"meeting|session|calendar|موعد|جلسة|اجتماع|put (it |a )?meeting", lower):
        return ActionType.CREATE_CALENDAR_EVENT
    return ActionType.CREATE_TASK


def _task_title(clause: str) -> str:
    cleaned = re.sub(
        r"\b(zakirne|zakerni|remind me|ذكرني|to|that|bokra|tomorrow|today|3al \d+|at \d+(am|pm)?)\b",
        " ",
        clause,
        flags=re.I,
    )
    cleaned = re.sub(r"\s+", " ", cleaned).strip(" .،")
    return cleaned or clause.strip()


def _email_body(clause: str) -> str:
    m = re.search(r"(?:that|قله|قلها|ello|ella|enno|enne)\s+(.+)$", clause, re.I)
    if m:
        return m.group(1).strip(" .")
    return clause


def _proposed_confirmation(action_type: ActionType) -> Confirmation:
    if action_type in {ActionType.PREPARE_WHATSAPP, ActionType.PREPARE_TELEGRAM, ActionType.PREPARE_SMS}:
        return Confirmation.HANDOFF
    if action_type in {
        ActionType.SEND_EMAIL,
        ActionType.CALL_CONTACT,
        ActionType.DELETE_CALENDAR_EVENT,
        ActionType.UPDATE_CALENDAR_EVENT,
        ActionType.SHARE_MEDIA,
    }:
        return Confirmation.CONFIRM
    return Confirmation.AUTO


def plan_utterance(request: PlanRequest) -> ActionPlan:
    now = parse_now(request.client_local_datetime, request.timezone)
    clauses = _split_clauses(request.text)
    actions: list[Action] = []
    clarification: Optional[Clarification] = None

    for index, clause in enumerate(clauses, start=1):
        action_type = _classify(clause)
        when = extract_datetime(clause, now) or extract_datetime(request.text, now)
        when_iso = when.isoformat() if when else None
        name = _extract_name(clause, request.text)
        contact, matches = (None, [])
        if name:
            contact, matches = _match_contact(name, request.context.candidate_contacts)
            if len(matches) > 1 and clarification is None:
                clarification = Clarification(
                    prompt=f"Which {name} did you mean?",
                    reason="ambiguous_person",
                    options=[c.display_name for c in matches],
                )

        recipient = None
        if name:
            recipient = Recipient(
                contact_id=contact.contact_id if contact else None,
                display_name=contact.display_name if contact else name,
                phone=contact.phone if contact else None,
                email=contact.email if contact else None,
            )

        confirmation = apply_policy_floor(action_type, _proposed_confirmation(action_type))
        action = Action(
            id=f"a{index}",
            type=action_type,
            status=ActionStatus.PLANNED,
            confirmation=confirmation,
            recipient=recipient,
        )

        if action_type == ActionType.CREATE_REMINDER:
            action.title = _task_title(clause)
            action.scheduled_for = when_iso
            action.remind_at = when_iso
        elif action_type == ActionType.CREATE_TASK:
            action.title = _task_title(clause)
            action.scheduled_for = when_iso
        elif action_type == ActionType.CREATE_CALENDAR_EVENT:
            title_name = name or "Event"
            kind = "Session" if re.search(r"session|جلسة", clause, re.I) else "Meeting"
            action.title = f"{kind} with {title_name}"
            action.start_at = when_iso
            if when:
                action.end_at = (when + timedelta(hours=1)).isoformat()
        elif action_type == ActionType.UPDATE_CALENDAR_EVENT:
            action.title = clause
            action.start_at = when_iso
            action.notes = clause
        elif action_type == ActionType.DELETE_CALENDAR_EVENT:
            action.title = clause
            action.notes = clause
        elif action_type in {ActionType.SEND_EMAIL, ActionType.DRAFT_EMAIL}:
            action.subject = "Quick note"
            action.message = _email_body(clause)
        elif action_type == ActionType.SEARCH_EMAIL:
            action.query = clause
        elif action_type == ActionType.CALL_CONTACT:
            action.title = f"Call {name or 'contact'}"
        elif action_type in {
            ActionType.PREPARE_WHATSAPP,
            ActionType.PREPARE_TELEGRAM,
            ActionType.PREPARE_SMS,
        }:
            action.message = compose_chat_message(clause, name)
            action.title = f"Message {name}" if name else "Message"
            meta = {}
            if when_iso:
                meta["proposed_session_time"] = when_iso
                action.scheduled_for = when_iso
            action.metadata = meta
        elif action_type == ActionType.SHARE_MEDIA:
            action.media_refs = ["device:selected"]
            action.message = clause
        elif action_type == ActionType.SAVE_NOTE:
            action.notes = clause
            action.title = "Note"
        elif action_type == ActionType.QUERY_CALENDAR:
            action.query = when.date().isoformat() if when else "upcoming"
            action.scheduled_for = when_iso
        elif action_type == ActionType.QUERY_TASKS:
            action.query = "overdue_or_unscheduled"
        elif action_type == ActionType.QUERY_MEMORY:
            action.query = clause
        elif action_type == ActionType.COMPLETE_TASK:
            action.title = _task_title(clause)

        actions.append(action)

    if not actions:
        clarification = Clarification(
            prompt="I didn't catch an action. Try a reminder, message, or calendar request.",
            reason="unsupported",
        )

    summary = _summarize(actions, request.text)
    confidence = 0.55 if clarification else 0.86
    return ActionPlan(
        plan_id=str(uuid.uuid4()),
        original_text=request.text,
        summary=summary,
        actions=actions,
        needs_clarification=clarification is not None,
        clarification=clarification,
        confidence=confidence,
    )


def _summarize(actions: list[Action], original: str) -> str:
    if not actions:
        return original
    bits = []
    for action in actions:
        label = action.type.value.replace("_", " ").title()
        who = action.recipient.display_name if action.recipient else None
        when = action.start_at or action.scheduled_for or action.remind_at
        piece = label
        if who:
            piece += f" for {who}"
        if when:
            piece += f" at {when}"
        bits.append(piece)
    return "; ".join(bits)
