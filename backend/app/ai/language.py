"""Lebanese / Arabizi / English hint layer. This is not the only parser."""

from __future__ import annotations

import re

# Longer phrases first.
PHRASE_MAP: list[tuple[str, str]] = [
    (r"\bday after tomorrow\b", "DAY_AFTER_TOMORROW"),
    (r"بعد بكرا", "DAY_AFTER_TOMORROW"),
    (r"\bba3d bokra\b", "DAY_AFTER_TOMORROW"),
    (r"\bbaad bokra\b", "DAY_AFTER_TOMORROW"),
    (r"\btomorrow\b", "TOMORROW"),
    (r"بكرا", "TOMORROW"),
    (r"غدا", "TOMORROW"),
    (r"\bbokra\b", "TOMORROW"),
    (r"\btoday\b", "TODAY"),
    (r"اليوم", "TODAY"),
    (r"\bhal2\b", "NOW"),
    (r"هلق", "NOW"),
    (r"\bhala2\b", "NOW"),
    (r"\bnow\b", "NOW"),
    (r"بعد شوي", "SHORTLY"),
    (r"\bba3d shway\b", "SHORTLY"),
    (r"\bin half an hour\b", "IN_30_MIN"),
    (r"نص ساعة", "IN_30_MIN"),
    (r"\bnos se3a\b", "IN_30_MIN"),
    (r"\bafter work\b", "AFTER_WORK"),
    (r"بعد الشغل", "AFTER_WORK"),
    (r"\bba3d l shoghl\b", "AFTER_WORK"),
    (r"\bba3d el shoghel\b", "AFTER_WORK"),
    (r"\bremind me\b", "REMIND"),
    (r"ذكرني", "REMIND"),
    (r"\bzakirne\b", "REMIND"),
    (r"\bzakerni\b", "REMIND"),
    (r"\bzakerni\b", "REMIND"),
    (r"\bcall\b", "CALL"),
    (r"دق", "CALL"),
    (r"\bde2\b", "CALL"),
    (r"\bde2e\b", "CALL"),
    (r"\bemail\b", "EMAIL"),
    (r"إيميل", "EMAIL"),
    (r"ايميل", "EMAIL"),
    (r"\bwhatsapp\b", "WHATSAPP"),
    (r"واتساب", "WHATSAPP"),
    (r"واتس", "WHATSAPP"),
    (r"\btelegram\b", "TELEGRAM"),
    (r"تلغرام", "TELEGRAM"),
    (r"\bsms\b", "SMS"),
    (r"\bmeeting\b", "MEETING"),
    (r"اجتماع", "MEETING"),
    (r"\bsession\b", "SESSION"),
    (r"جلسة", "SESSION"),
    (r"\bsoboh\b", "MORNING"),
    (r"صبح", "MORNING"),
    (r"\bmorning\b", "MORNING"),
    (r"\bmasa\b", "EVENING"),
    (r"مسا", "EVENING"),
    (r"\bevening\b", "EVENING"),
    (r"شو عندي", "QUERY_SCHEDULE"),
    (r"\bshu 3ande\b", "QUERY_SCHEDULE"),
    (r"\bshu 3andi\b", "QUERY_SCHEDULE"),
    (r"\bwhat am i forgetting\b", "QUERY_FORGETTING"),
    (r"شو نسيت", "QUERY_FORGETTING"),
    (r"ابعت", "SEND"),
    (r"\beb3at\b", "SEND"),
    (r"\beb3et\b", "SEND"),
    (r"\bsend\b", "SEND"),
    (r"قلو", "TELL"),
    (r"قلها", "TELL"),
    (r"\bello\b", "TELL"),
    (r"\bella\b", "TELL"),
    (r"\bask\b", "ASK"),
    (r"اسأل", "ASK"),
    (r"اسال", "ASK"),
]


def fold_arabizi_digits(text: str) -> str:
    """Keep original text; this helper only helps matching."""
    return text


def contains_arabic(text: str) -> bool:
    return bool(re.search(r"[\u0600-\u06FF]", text))
