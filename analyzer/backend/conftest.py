"""Shared pytest fixtures for backend tests."""

import json
import time
from unittest.mock import MagicMock

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def tmp_db(tmp_path, monkeypatch):
    db_dir = tmp_path / "agent-analyzer"
    db_dir.mkdir()
    monkeypatch.setenv("ANALYZER_DB_DIR", str(db_dir))

    import db

    db.DB_DIR = db_dir
    db.DB_PATH = db_dir / "flows.db"
    db.init_db()
    conn = db.get_db()
    yield conn
    conn.close()


@pytest.fixture
def sample_flows():
    now = time.time()
    return [
        {
            "id": "flow-ai-1",
            "flow_type": "ai",
            "agent": "claude",
            "provider": "anthropic",
            "method": "POST",
            "scheme": "https",
            "host": "api.anthropic.com",
            "path": "/v1/messages",
            "query": "",
            "status_code": 200,
            "content_type_req": "application/json",
            "content_type_res": "text/event-stream",
            "timestamp_start": now - 2,
            "timestamp_end": now - 1,
            "latency_ms": 1000,
            "ttfb_ms": 200,
            "request_size": 10,
            "response_size": 20,
            "request_headers": json.dumps({"content-type": "application/json"}),
            "response_headers": json.dumps({"content-type": "text/event-stream"}),
            "request_body": b"{}",
            "response_body": b"data: {}\n\n",
            "is_error": 0,
            "is_replay": 0,
            "tags": json.dumps(["streaming"]),
        },
        {
            "id": "flow-auth-1",
            "flow_type": "auth",
            "agent": None,
            "provider": None,
            "method": "POST",
            "scheme": "https",
            "host": "auth.openai.com",
            "path": "/oauth/token",
            "query": "",
            "status_code": 200,
            "content_type_req": "application/json",
            "content_type_res": "application/json",
            "timestamp_start": now - 4,
            "timestamp_end": now - 3,
            "latency_ms": 1000,
            "ttfb_ms": 200,
            "request_size": 10,
            "response_size": 20,
            "request_headers": json.dumps({"content-type": "application/json"}),
            "response_headers": json.dumps({"content-type": "application/json"}),
            "request_body": b"{}",
            "response_body": b"{}",
            "is_error": 0,
            "is_replay": 0,
            "tags": json.dumps([]),
        },
    ]


@pytest.fixture
def seeded_db(tmp_db, sample_flows):
    from db import insert_flow

    for flow in sample_flows:
        insert_flow(tmp_db, flow)
    return tmp_db


@pytest.fixture
def api_client(seeded_db):
    from server import app

    return TestClient(app)


def make_mock_flow(host="api.anthropic.com", flow_id="mock-1", status_code=200, response_content_type="text/event-stream"):
    flow = MagicMock()
    flow.id = flow_id
    flow.is_replay = False
    flow.request.host = host
    flow.request.path = "/v1/messages"
    flow.request.method = "POST"
    flow.request.scheme = "https"
    flow.request.content = b'{"a":1}'
    flow.request.timestamp_start = time.time() - 3
    flow.request.query = MagicMock()
    flow.request.query.__str__.return_value = ""
    flow.request.headers = MagicMock()
    flow.request.headers.get = lambda key, default=None: {"content-type": "application/json"}.get(key, default)
    flow.request.headers.items = lambda multi=False: [("content-type", "application/json")]

    flow.response.status_code = status_code
    flow.response.content = b'data: {"ok":true}\n\n'
    flow.response.timestamp_start = time.time() - 2.8
    flow.response.timestamp_end = time.time() - 2
    flow.response.headers = MagicMock()
    flow.response.headers.get = lambda key, default=None: {"content-type": response_content_type}.get(key, default)
    flow.response.headers.items = lambda multi=False: [("content-type", response_content_type)]
    return flow
