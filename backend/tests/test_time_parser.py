from app.ai.time_parser import extract_datetime, parse_now

NOW = parse_now("2026-08-16T22:00:00+03:00", "Asia/Beirut")


def test_bokra_3al_5_is_tomorrow_evening() -> None:
    dt = extract_datetime("zakirne bokra 3al 5 jib l siyara", NOW)
    assert dt is not None
    assert dt.day == 17
    assert dt.hour == 17


def test_thursday_at_2() -> None:
    dt = extract_datetime("meeting Thursday at 2", NOW)
    assert dt is not None
    assert dt.weekday() == 3
    assert dt.hour == 14


def test_in_half_an_hour() -> None:
    dt = extract_datetime("remind me in half an hour", NOW)
    assert dt is not None
    assert dt.hour == 22
    assert dt.minute == 30


def test_after_30_seconds() -> None:
    dt = extract_datetime("after 30 seconds", NOW)
    assert dt is not None
    assert (dt - NOW).total_seconds() == 30
