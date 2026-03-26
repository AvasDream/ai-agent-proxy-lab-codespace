"""FastAPI server for agent-analyzer."""

import asyncio
import json
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from db import get_db

app = FastAPI(title="agent-analyzer")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/api/flows")
def list_flows(
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    flow_type: str | None = None,
    host: str | None = None,
    agent: str | None = None,
    status_min: int | None = None,
    status_max: int | None = None,
    search: str | None = None,
    since: float | None = None,
    until: float | None = None,
    errors_only: bool = False,
):
    conn = get_db()
    conditions: list[str] = []
    params: list[object] = []

    if flow_type:
        conditions.append("flow_type = ?")
        params.append(flow_type)
    if host:
        conditions.append("host LIKE ?")
        params.append(f"%{host}%")
    if agent:
        conditions.append("agent = ?")
        params.append(agent)
    if status_min is not None:
        conditions.append("status_code >= ?")
        params.append(status_min)
    if status_max is not None:
        conditions.append("status_code <= ?")
        params.append(status_max)
    if search:
        conditions.append("(host LIKE ? OR path LIKE ?)")
        params.extend([f"%{search}%", f"%{search}%"])
    if since is not None:
        conditions.append("timestamp_start >= ?")
        params.append(since)
    if until is not None:
        conditions.append("timestamp_start <= ?")
        params.append(until)
    if errors_only:
        conditions.append("is_error = 1")

    where_clause = f"WHERE {' AND '.join(conditions)}" if conditions else ""

    total = conn.execute(f"SELECT COUNT(*) AS c FROM flows {where_clause}", params).fetchone()["c"]
    rows = conn.execute(
        f"""SELECT id, flow_type, agent, provider, method, scheme, host, path,
                   query, status_code, content_type_req, content_type_res,
                   timestamp_start, timestamp_end, latency_ms, ttfb_ms,
                   request_size, response_size, is_error, is_replay, tags
            FROM flows {where_clause}
            ORDER BY timestamp_start DESC
            LIMIT ? OFFSET ?""",
        params + [limit, offset],
    ).fetchall()
    conn.close()
    return {"total": total, "limit": limit, "offset": offset, "flows": [dict(r) for r in rows]}


@app.get("/api/flows/{flow_id}")
def get_flow(flow_id: str):
    conn = get_db()
    row = conn.execute("SELECT * FROM flows WHERE id = ?", [flow_id]).fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="not found")

    result = dict(row)
    for field in ("request_body", "response_body"):
        body = result.get(field)
        if isinstance(body, (bytes, bytearray)):
            result[field] = body.decode("utf-8", errors="replace")
    for field in ("request_headers", "response_headers", "tags"):
        if result.get(field):
            result[field] = json.loads(result[field])
    return result


@app.get("/api/stats")
def get_stats():
    conn = get_db()
    total = conn.execute("SELECT COUNT(*) AS c FROM flows").fetchone()["c"]
    by_type = conn.execute("SELECT flow_type, COUNT(*) AS c FROM flows GROUP BY flow_type").fetchall()
    by_agent = conn.execute("SELECT agent, COUNT(*) AS c FROM flows WHERE agent IS NOT NULL GROUP BY agent").fetchall()
    by_host = conn.execute("SELECT host, COUNT(*) AS c, flow_type FROM flows GROUP BY host ORDER BY c DESC LIMIT 20").fetchall()
    errors = conn.execute("SELECT COUNT(*) AS c FROM flows WHERE is_error = 1").fetchone()["c"]
    avg_latency = conn.execute("SELECT AVG(latency_ms) AS avg FROM flows WHERE latency_ms IS NOT NULL").fetchone()["avg"]
    db_size = conn.execute("SELECT page_count * page_size AS size FROM pragma_page_count(), pragma_page_size()").fetchone()["size"]
    conn.close()
    return {
        "total_flows": total,
        "by_type": {r["flow_type"]: r["c"] for r in by_type},
        "by_agent": {r["agent"]: r["c"] for r in by_agent},
        "top_hosts": [{"host": r["host"], "count": r["c"], "flow_type": r["flow_type"]} for r in by_host],
        "errors": errors,
        "avg_latency_ms": round(avg_latency, 1) if avg_latency else None,
        "db_size_bytes": db_size,
    }


@app.delete("/api/flows")
def prune_flows(older_than: float | None = None, flow_type: str | None = None):
    conn = get_db()
    conditions: list[str] = []
    params: list[object] = []
    if older_than is not None:
        conditions.append("timestamp_start < ?")
        params.append(older_than)
    if flow_type:
        conditions.append("flow_type = ?")
        params.append(flow_type)
    if not conditions:
        conn.close()
        raise HTTPException(status_code=400, detail="must specify at least one filter")
    result = conn.execute(f"DELETE FROM flows WHERE {' AND '.join(conditions)}", params)
    conn.commit()
    deleted = result.rowcount
    conn.close()
    return {"deleted": deleted}


@app.websocket("/api/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    try:
        from addon import subscribe, unsubscribe

        q = subscribe()
    except Exception:
        q = None

    try:
        if q:
            while True:
                event = await asyncio.get_running_loop().run_in_executor(None, q.get)
                await ws.send_json(event)
        else:
            last_ts = 0.0
            while True:
                await asyncio.sleep(1)
                conn = get_db()
                rows = conn.execute(
                    """SELECT id, flow_type, agent, provider, method, host, path,
                              status_code, timestamp_start, latency_ms, request_size,
                              response_size, is_error, tags
                       FROM flows WHERE timestamp_start > ?
                       ORDER BY timestamp_start ASC LIMIT 50""",
                    [last_ts],
                ).fetchall()
                conn.close()
                for row in rows:
                    data = dict(row)
                    await ws.send_json(data)
                    last_ts = max(last_ts, data["timestamp_start"])
    except WebSocketDisconnect:
        pass
    finally:
        if q:
            unsubscribe(q)


frontend_dist = Path(__file__).parent.parent / "frontend" / "dist"
if frontend_dist.exists():
    app.mount("/", StaticFiles(directory=str(frontend_dist), html=True), name="frontend")
