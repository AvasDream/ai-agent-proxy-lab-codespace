#!/bin/bash
set -euo pipefail

API_PORT=18555
DB_DIR=$(mktemp -d)
BACKEND_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
PID=""

cleanup() {
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
  fi
  rm -rf "$DB_DIR"
}
trap cleanup EXIT

export ANALYZER_DB_DIR="$DB_DIR"

cd "$BACKEND_DIR"
python3 -c "from db import init_db; init_db()"
python3 -c "import json,time; from db import get_db,insert_flow; c=get_db(); insert_flow(c, {'id':'e2e-1','flow_type':'ai','agent':'claude','provider':'anthropic','method':'POST','scheme':'https','host':'api.anthropic.com','path':'/v1/messages','query':'','status_code':200,'content_type_req':'application/json','content_type_res':'application/json','timestamp_start':time.time()-2,'timestamp_end':time.time()-1,'latency_ms':1000,'ttfb_ms':200,'request_size':1,'response_size':1,'request_headers':json.dumps({}),'response_headers':json.dumps({}),'request_body':b'{}','response_body':b'{}','is_error':0,'is_replay':0,'tags':json.dumps([])}); c.close()"

uvicorn server:app --host 127.0.0.1 --port "$API_PORT" --log-level error &
PID=$!
sleep 2

TOTAL=$(curl -sf "http://127.0.0.1:$API_PORT/api/flows" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")
[ "$TOTAL" -ge 1 ]

AI=$(curl -sf "http://127.0.0.1:$API_PORT/api/flows?flow_type=ai" | python3 -c "import json,sys; print(json.load(sys.stdin)['total'])")
[ "$AI" -ge 1 ]

echo "E2E passed"
