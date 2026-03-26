"""SQLite helpers and schema for agent-analyzer."""

import os
import sqlite3
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS flows (
    id TEXT PRIMARY KEY,
    flow_type TEXT NOT NULL DEFAULT 'other',
    agent TEXT,
    provider TEXT,
    method TEXT NOT NULL,
    scheme TEXT NOT NULL DEFAULT 'https',
    host TEXT NOT NULL,
    path TEXT NOT NULL,
    query TEXT DEFAULT '',
    status_code INTEGER,
    content_type_req TEXT,
    content_type_res TEXT,
    timestamp_start REAL NOT NULL,
    timestamp_end REAL,
    latency_ms REAL,
    ttfb_ms REAL,
    request_size INTEGER DEFAULT 0,
    response_size INTEGER DEFAULT 0,
    request_headers TEXT,
    response_headers TEXT,
    request_body BLOB,
    response_body BLOB,
    is_error INTEGER DEFAULT 0,
    is_replay INTEGER DEFAULT 0,
    tags TEXT DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_flows_timestamp ON flows(timestamp_start);
CREATE INDEX IF NOT EXISTS idx_flows_host ON flows(host);
CREATE INDEX IF NOT EXISTS idx_flows_type ON flows(flow_type);
CREATE INDEX IF NOT EXISTS idx_flows_status ON flows(status_code);
CREATE INDEX IF NOT EXISTS idx_flows_agent ON flows(agent);
"""

DB_DIR = Path(os.environ.get("ANALYZER_DB_DIR", "/home/node/.agent-analyzer"))
DB_PATH = DB_DIR / "flows.db"


def get_db() -> sqlite3.Connection:
    DB_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA synchronous=NORMAL")
    return conn


def init_db() -> None:
    conn = get_db()
    conn.executescript(SCHEMA)
    conn.close()


def insert_flow(conn: sqlite3.Connection, flow_dict: dict) -> None:
    cols = list(flow_dict.keys())
    placeholders = ", ".join(["?"] * len(cols))
    col_names = ", ".join(cols)
    conn.execute(
        f"INSERT OR REPLACE INTO flows ({col_names}) VALUES ({placeholders})",
        [flow_dict[col] for col in cols],
    )
    conn.commit()
