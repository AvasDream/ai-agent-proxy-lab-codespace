#!/bin/bash
set -e

PROXY_PORT="${PROXY_PORT:-8080}"
WEB_PORT="${WEB_PORT:-8081}"
API_PORT="${API_PORT:-5555}"
ANALYZER_DIR="${ANALYZER_DIR:-/workspace/ai-agent-proxy-lab-codespace/analyzer}"

echo "🔬 Starting agent-analyzer"
uvicorn --app-dir "${ANALYZER_DIR}/backend" server:app --host 0.0.0.0 --port "${API_PORT}" --log-level warning &
API_PID=$!
sleep 1

trap "kill $API_PID 2>/dev/null || true; exit 0" INT TERM

exec mitmweb \
  --listen-port "$PROXY_PORT" \
  --web-port "$WEB_PORT" \
  --web-host "0.0.0.0" \
  --no-web-open-browser \
  --set "confdir=/home/node/.mitmproxy" \
  --set "flow_detail=0" \
  -s "${ANALYZER_DIR}/backend/addon.py"
