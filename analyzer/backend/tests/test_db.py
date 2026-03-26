from db import init_db, insert_flow


def test_init_db_idempotent(tmp_db):
    init_db()
    init_db()
    row = tmp_db.execute("SELECT COUNT(*) AS c FROM sqlite_master WHERE type='table' AND name='flows'").fetchone()
    assert row["c"] == 1


def test_insert_flow(tmp_db, sample_flows):
    insert_flow(tmp_db, sample_flows[0])
    row = tmp_db.execute("SELECT * FROM flows WHERE id='flow-ai-1'").fetchone()
    assert row is not None
    assert row["flow_type"] == "ai"
