def test_list_flows(api_client):
    res = api_client.get('/api/flows')
    assert res.status_code == 200
    body = res.json()
    assert body['total'] == 2


def test_flow_detail(api_client):
    res = api_client.get('/api/flows/flow-ai-1')
    assert res.status_code == 200
    body = res.json()
    assert body['id'] == 'flow-ai-1'
    assert isinstance(body['request_headers'], dict)


def test_stats(api_client):
    res = api_client.get('/api/stats')
    assert res.status_code == 200
    assert res.json()['total_flows'] == 2
