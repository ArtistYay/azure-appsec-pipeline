import json
import logging

import pytest

from app.app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def parse_events(caplog):
    """Return every JSON log line the app wrote during the test, as dictionaries."""
    return [json.loads(record.getMessage()) for record in caplog.records]


def test_health_returns_200_and_json(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {
        "status": "healthy",
        "message": "azure-appsec-pipeline is running",
    }


def test_health_logs_structured_event(client, caplog):
    with caplog.at_level(logging.INFO):
        client.get("/health")

    events = parse_events(caplog)
    assert events[-1]["event"] == "health_check"
    assert events[-1]["status"] == 200


def test_unknown_path_logs_not_found(client, caplog):
    with caplog.at_level(logging.INFO):
        response = client.get("/admin")

    assert response.status_code == 404
    event = parse_events(caplog)[-1]
    assert event["event"] == "not_found"
    assert event["path"] == "/admin"


def test_wrong_method_logs_method_not_allowed(client, caplog):
    with caplog.at_level(logging.INFO):
        response = client.post("/health")

    assert response.status_code == 405
    event = parse_events(caplog)[-1]
    assert event["event"] == "method_not_allowed"
    assert event["method"] == "POST"


def test_client_ip_trusts_only_last_forwarded_value(client, caplog):
    # A client can send its own fake X-Forwarded-For. The ingress appends the real IP last.
    headers = {"X-Forwarded-For": "1.2.3.4, 203.0.113.7"}
    with caplog.at_level(logging.INFO):
        client.get("/does-not-exist", headers=headers)

    assert parse_events(caplog)[-1]["client_ip"] == "203.0.113.7"


def test_user_agent_is_truncated(client, caplog):
    with caplog.at_level(logging.INFO):
        client.get("/health", headers={"User-Agent": "A" * 5000})

    assert len(parse_events(caplog)[-1]["user_agent"]) == 200
