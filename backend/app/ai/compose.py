"""Turn a command into a message the recipient should read — never the raw command."""

from __future__ import annotations

import re
from typing import Optional

_STOP = {
    "send",
    "sent",
    "a",
    "an",
    "the",
    "hi",
    "hello",
    "hey",
    "message",
    "msg",
    "whatsapp",
    "telegram",
    "sms",
    "to",
    "for",
    "please",
    "on",
    "in",
    "after",
    "before",
    "me",
    "my",
    "her",
    "him",
    "them",
}

_DURATION = re.compile(
    r"\b(?:in|after)\s+\d+\s+(?:seconds?|secs?|minutes?|mins?|hours?|hrs?)\b",
    re.I,
)


def compose_chat_message(clause: str, name: Optional[str]) -> str:
    who = (name or "there").strip().title()
    text = _DURATION.sub(" ", clause)
    text = re.sub(r"\b\d+\s+(?:seconds?|secs?|minutes?|mins?|hours?|hrs?)\b", " ", text, flags=re.I)
    lower = text.lower()

    if re.search(r"session|جلسة", lower):
        return f"Hi {who}, how are you? Would you like to take a session?"

    quoted = re.search(r"[\"“](.+?)[\"”]", text)
    if quoted:
        return quoted.group(1).strip()

    saying = re.search(
        r"(?:saying|that|قله|قلها|ello|ella|enno|enne)\s+(.+)$",
        text,
        re.I,
    )
    if saying:
        body = saying.group(1).strip(" .")
        body = re.sub(rf"\b{re.escape(who)}\b", "", body, flags=re.I).strip(" ,.")
        if body:
            return f"Hi {who}, {body[0].lower() + body[1:] if len(body) > 1 else body}"
        return f"Hi {who}"

    greeting_only = bool(re.search(r"\b(hi|hello|hey|salam|marhaba|مرحبا)\b", lower))
    leftover = _strip_command(text, who)
    if greeting_only and not leftover:
        return f"Hi {who}"
    if leftover:
        if greeting_only:
            return f"Hi {who}, {leftover}"
        return leftover if leftover[0].isupper() else leftover[0].upper() + leftover[1:]
    return f"Hi {who}"


def _strip_command(text: str, who: str) -> str:
    cleaned = text
    cleaned = re.sub(r"\b(send|eb3at|ابعت|ask|tell)\b", " ", cleaned, flags=re.I)
    cleaned = re.sub(r"\b(a|an|the)?\s*(hi|hello|hey)?\s*(message|msg|whatsapp)\b", " ", cleaned, flags=re.I)
    cleaned = re.sub(rf"\b(for|to|la)\s+{re.escape(who)}\b", " ", cleaned, flags=re.I)
    cleaned = re.sub(rf"\b{re.escape(who)}\b", " ", cleaned, flags=re.I)
    tokens = [tok for tok in re.split(r"\s+", cleaned.strip(" .,")) if tok and tok.lower() not in _STOP]
    return " ".join(tokens).strip(" .,")
