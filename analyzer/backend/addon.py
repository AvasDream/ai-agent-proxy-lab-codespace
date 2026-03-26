"""mitmproxy addon that stores captured flows in SQLite."""

import asyncio
import json
import logging
import os
import time

from mitmproxy import http

from classifier import classify
from db import get_db, init_db, insert_flow

logger = logging.getLogger("agent-analyzer")

_ws_subscribers: list[asyncio.Queue] = []


def subscribe() -> asyncio.Queue:
    q: asyncio.Queue = asyncio.Queue(maxsize=200)
    _ws_subscribers.append(q)
    return q


def unsubscribe(q: asyncio.Queue) -> None:
    if q in _ws_subscribers:
        _ws_subscribers.remove(q)


class AgentAnalyzer:
    def __init__(self) -> None:
        init_db()
        self.conn = get_db()
        self.body_mode = os.environ.get("ANALYZER_BODY_MODE", "full").lower()

    @staticmethod
    def _serialize_headers(headers) -> str:
        return json.dumps(dict(headers.items(multi=True)))

    @staticmethod
    def _safe_body(content: bytes | None, max_bytes: int = 5_000_000) -> bytes | None:
        if content is None:
            return None
        return content[:max_bytes]

    def response(self, flow: http.HTTPFlow) -> None:
        try:
            self._store_flow(flow)
        except Exception as exc:
            logger.error("failed to store flow: %s", exc)

    def _store_flow(self, flow: http.HTTPFlow) -> None:
        req = flow.request
        res = flow.response

        flow_type, provider, agent = classify(req.host)

        ts_start = req.timestamp_start
        ts_end = res.timestamp_end if res else None
        ttfb_ms = (res.timestamp_start - ts_start) * 1000 if res and res.timestamp_start else None
        latency_ms = (ts_end - ts_start) * 1000 if ts_end else None

        tags: list[str] = []
        if res and (res.headers.get("content-type") or "").startswith("text/event-stream"):
            tags.append("streaming")
        if res and res.status_code == 429:
            tags.append("rate_limit")

        request_body = self._safe_body(req.content)
        response_body = self._safe_body(res.content if res else None)
        if self.body_mode == "none":
            request_body = None
            response_body = None
        if self.body_mode == "ai_only" and flow_type != "ai":
            request_body = None
            response_body = None

        query = ""
        if hasattr(req, "query") and req.query is not None:
            try:
                query = str(req.query)
            except Exception:
                query = ""

        flow_dict = {
            "id": flow.id,
            "flow_type": flow_type,
            "agent": agent,
            "provider": provider,
            "method": req.method,
            "scheme": req.scheme,
            "host": req.host,
            "path": req.path,
            "query": query,
            "status_code": res.status_code if res else None,
            "content_type_req": req.headers.get("content-type"),
            "content_type_res": res.headers.get("content-type") if res else None,
            "timestamp_start": ts_start,
            "timestamp_end": ts_end,
            "latency_ms": latency_ms,
            "ttfb_ms": ttfb_ms,
            "request_size": len(req.content) if req.content else 0,
            "response_size": len(res.content) if res and res.content else 0,
            "request_headers": self._serialize_headers(req.headers),
            "response_headers": self._serialize_headers(res.headers) if res else "{}",
            "request_body": request_body,
            "response_body": response_body,
            "is_error": 1 if res and res.status_code >= 400 else 0,
            "is_replay": 1 if flow.is_replay else 0,
            "tags": json.dumps(tags),
        }
        insert_flow(self.conn, flow_dict)

        ws_event = {k: v for k, v in flow_dict.items() if k not in {"request_body", "response_body", "request_headers", "response_headers"}}
        ws_event["timestamp_start_iso"] = (
            time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(ts_start))
            + f".{int((ts_start % 1) * 1000):03d}Z"
        )

        for q in list(_ws_subscribers):
            try:
                q.put_nowait(ws_event)
            except asyncio.QueueFull:
                continue

    def done(self) -> None:
        self.conn.close()


addons = [AgentAnalyzer()]
