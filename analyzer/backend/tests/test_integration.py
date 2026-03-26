from conftest import make_mock_flow
from fastapi.testclient import TestClient


def test_addon_to_api(tmp_db):
    from addon import AgentAnalyzer
    from server import app

    addon = AgentAnalyzer()
    addon.response(make_mock_flow(flow_id='integration-1'))
    client = TestClient(app)
    res = client.get('/api/flows?flow_type=ai')
    ids = [f['id'] for f in res.json()['flows']]
    assert 'integration-1' in ids
