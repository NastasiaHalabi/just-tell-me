from __future__ import annotations

import re
from datetime import datetime, timedelta
from typing import Optional
from zoneinfo import ZoneInfo

from dateutil import parser as date_parser

WEEKDAYS = {
    "monday": 0,
    "tuesday": 1,
    "wednesday": 2,
    "thursday": 3,
    "friday": 4,
    "saturday": 5,
    "sunday": 6,
    "الاثنين": 0,
    "الثلاثاء": 1,
    "الاربعاء": 2,
    "الأربعاء": 2,
    "الخميس": 3,
    "الجمعة": 4,
    "السبت": 5,
    "الاحد": 6,
    "الأحد": 6,
}

ARABIZI_WEEKDAYS = {
    "tnen": 0,
    "tlate": 1,
    "arba3a": 2,
    "khamis": 3,
    "jomaa": 4,
    "jumaa": 4,
    "sabet": 5,
    "ahad": 6,
}


def parse_now(client_local_datetime: str, timezone: str) -> datetime:
    tz = ZoneInfo(timezone)
    try:
        dt = date_parser.isoparse(client_local_datetime)
        if dt.tzinfo is None:
            return dt.replace(tzinfo=tz)
        return dt.astimezone(tz)
    except (ValueError, OverflowError):
        return datetime.now(tz)


def next_weekday(now: datetime, weekday: int) -> datetime:
    days = (weekday - now.weekday()) % 7
    if days == 0:
        days = 7
    return (now + timedelta(days=days)).replace(hour=9, minute=0, second=0, microsecond=0)


def _hour_from_token(token: str, evening_bias: bool) -> Optional[int]:
    try:
        hour = int(token)
    except ValueError:
        return None
    if hour > 23:
        return None
    if hour <= 7 and evening_bias:
        return hour + 12
    return hour


def extract_clock(text: str, now: datetime) -> Optional[datetime]:
    """Parse times like 3pm, 15:00, 3al 5, عالخمسة, at 2."""
    lower = text.lower()
    evening_bias = not any(
        token in lower for token in ("soboh", "صبح", "morning", "am", "صباح")
    )

    m = re.search(r"\b(\d{1,2}):(\d{2})\s*(am|pm)?\b", lower, re.I)
    if m:
        hour = int(m.group(1))
        minute = int(m.group(2))
        meridiem = (m.group(3) or "").lower()
        if meridiem == "pm" and hour < 12:
            hour += 12
        if meridiem == "am" and hour == 12:
            hour = 0
        return now.replace(hour=hour, minute=minute, second=0, microsecond=0)

    m = re.search(r"\b(\d{1,2})\s*(am|pm)\b", lower)
    if m:
        hour = int(m.group(1))
        if m.group(2).lower() == "pm" and hour < 12:
            hour += 12
        if m.group(2).lower() == "am" and hour == 12:
            hour = 0
        return now.replace(hour=hour, minute=0, second=0, microsecond=0)

    m = re.search(r"(?:3al|3a|at|@|عال|عال)\s*(\d{1,2})", lower)
    if m:
        hour = _hour_from_token(m.group(1), evening_bias)
        if hour is not None:
            return now.replace(hour=hour, minute=0, second=0, microsecond=0)

    arabic_hours = {
        "واحدة": 1,
        "تنين": 2,
        "تين": 2,
        "تلاتة": 3,
        "ثلاثة": 3,
        "اربعة": 4,
        "أربعة": 4,
        "خمسة": 5,
        "ستة": 6,
        "سبعة": 7,
        "تمانية": 8,
        "ثمانية": 8,
        "تسعة": 9,
        "عشرة": 10,
        "حدعش": 11,
        "طعش": 12,
        "اثنعش": 12,
    }
    for word, hour in arabic_hours.items():
        if word in text:
            resolved = hour + 12 if evening_bias and hour <= 7 else hour
            if resolved == 24:
                resolved = 12
            return now.replace(hour=resolved % 24, minute=0, second=0, microsecond=0)
    return None


def extract_datetime(text: str, now: datetime) -> Optional[datetime]:
    lower = text.lower()
    base = now

    relative = re.search(
        r"\b(?:in|after)\s+(\d+)\s+(seconds?|secs?|minutes?|mins?|hours?|hrs?)\b",
        lower,
    )
    if relative:
        amount = int(relative.group(1))
        unit = relative.group(2)
        if unit.startswith("sec"):
            return now + timedelta(seconds=amount)
        if unit.startswith("min"):
            return now + timedelta(minutes=amount)
        return now + timedelta(hours=amount)

    if re.search(r"بعد بكرا|ba3d bokra|day after tomorrow", lower):
        base = now + timedelta(days=2)
    elif re.search(r"\bbokra\b|بكرا|غدا|\btomorrow\b", lower):
        base = now + timedelta(days=1)
    elif re.search(r"اليوم|\btoday\b", lower):
        base = now
    elif re.search(r"هلق|\bhala2\b|\bnow\b", lower):
        return now
    elif re.search(r"بعد شوي|ba3d shway|shortly", lower):
        return now + timedelta(minutes=20)
    elif re.search(r"in half an hour|نص ساعة|nos se3a", lower):
        return now + timedelta(minutes=30)
    else:
        for name, weekday in {**WEEKDAYS, **ARABIZI_WEEKDAYS}.items():
            if re.search(rf"\b{re.escape(name)}\b", lower) or name in text:
                base = next_weekday(now, weekday)
                break
        else:
            if re.search(r"after work|بعد الشغل|ba3d l shoghl|ba3d el shoghel", lower):
                candidate = now.replace(hour=18, minute=0, second=0, microsecond=0)
                if candidate <= now:
                    candidate += timedelta(days=1)
                return candidate

    clock = extract_clock(text, base)
    if clock is not None:
        if clock.date() == now.date() and clock <= now and "today" not in lower and "اليوم" not in text:
            if base.date() != now.date():
                return clock.replace(year=base.year, month=base.month, day=base.day)
        return clock.replace(year=base.year, month=base.month, day=base.day)

    if base.date() != now.date():
        return base.replace(hour=9, minute=0, second=0, microsecond=0)
    return None
