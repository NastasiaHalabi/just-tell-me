import json
from pathlib import Path

from tests.golden_source import all_cases


def test_golden_corpus_size() -> None:
    cases = all_cases()
    langs = {c["lang"] for c in cases}
    assert "en" in langs and "ar" in langs and "arabizi" in langs
    assert len([c for c in cases if c["lang"] == "en"]) >= 25
    assert len([c for c in cases if c["lang"] == "ar"]) >= 25
    assert len([c for c in cases if c["lang"] == "arabizi"]) >= 50
    assert len(cases) >= 100


def write_json() -> Path:
    path = Path(__file__).resolve().parents[2] / "shared" / "golden" / "utterances.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(all_cases(), ensure_ascii=False, indent=2), encoding="utf-8")
    return path
