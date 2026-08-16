from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_plan_endpoint_validates_schema() -> None:
    response = client.post(
        "/v1/plan",
        json={
            "text": "zakirne bokra 3al 5 jib l siyara",
            "client_local_datetime": "2026-08-16T22:00:00+03:00",
            "timezone": "Asia/Beirut",
            "locale_hints": ["en", "ar-LB"],
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["schema_version"] == "1.0"
    assert body["actions"][0]["type"] == "CREATE_REMINDER"
