import json

from conftest import make_mock_flow


def test_addon_stores_flow(tmp_db):
    from addon import AgentAnalyzer

    addon = AgentAnalyzer()
    addon.response(make_mock_flow(flow_id="addon-1"))
    row = tmp_db.execute("SELECT * FROM flows WHERE id='addon-1'").fetchone()
    assert row is not None
    assert row["flow_type"] == "ai"


def test_addon_tags_rate_limit(tmp_db):
    from addon import AgentAnalyzer

    addon = AgentAnalyzer()
    addon.response(make_mock_flow(flow_id="addon-429", status_code=429, response_content_type="application/json"))
    row = tmp_db.execute("SELECT tags, is_error FROM flows WHERE id='addon-429'").fetchone()
    assert row["is_error"] == 1
    assert "rate_limit" in json.loads(row["tags"])
