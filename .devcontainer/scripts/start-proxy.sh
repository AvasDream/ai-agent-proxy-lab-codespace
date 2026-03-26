#!/bin/bash
set -e

PROXY_PORT="${PROXY_PORT:-8080}"
WEB_PORT="${WEB_PORT:-8081}"
FLOW_FILE=""
ANALYZE=false
API_PORT="${API_PORT:-5555}"
TOKEN_FILE="/home/node/.mitmproxy/mitmweb-token"
WEB_PASSWORD="${MITMWEB_PASSWORD:-}"

usage() {
  echo "Usage: start-proxy [OPTIONS]"
  echo ""
  echo "Start mitmweb for HTTP(S) traffic interception."
  echo ""
  echo "Options:"
  echo "  -p, --proxy-port PORT   Proxy listen port (default: 8080)"
  echo "  -w, --web-port PORT     mitmweb UI port (default: 8081)"
  echo "  -f, --flow-file FILE    Save flows to file for later replay"
  echo "  -a, --analyze           Enable analyzer capture + API server"
  echo "  -h, --help              Show this help"
  echo ""
  echo "Examples:"
  echo "  start-proxy                          # defaults"
  echo "  start-proxy -f /tmp/capture.flow     # save flows to file"
  echo "  start-proxy -p 9090 -w 9091          # custom ports"
}

while [ $# -gt 0 ]; do
  case "$1" in
    -p|--proxy-port) PROXY_PORT="$2"; shift 2 ;;
    -w|--web-port)   WEB_PORT="$2"; shift 2 ;;
    -f|--flow-file)  FLOW_FILE="$2"; shift 2 ;;
    -a|--analyze)    ANALYZE=true; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$WEB_PASSWORD" ]; then
  if [ -f "$TOKEN_FILE" ]; then
    WEB_PASSWORD="$(cat "$TOKEN_FILE")"
  else
    WEB_PASSWORD="$(openssl rand -hex 24)"
    mkdir -p /home/node/.mitmproxy
    printf '%s' "$WEB_PASSWORD" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
  fi
fi

if [ -n "$CODESPACES" ]; then
  WEB_BASE_URL="https://${CODESPACE_NAME}-${WEB_PORT}.app.github.dev"
else
  WEB_BASE_URL="http://localhost:${WEB_PORT}"
fi
WEB_AUTH_URL="${WEB_BASE_URL}/?token=${WEB_PASSWORD}"

if ss -tln 2>/dev/null | grep -q ":${PROXY_PORT} " || \
   lsof -i ":${PROXY_PORT}" &>/dev/null; then
  echo "⚠  Port ${PROXY_PORT} is already in use."
  echo "   If mitmweb is already running, open the UI:"
  echo "   ${WEB_AUTH_URL}"
  echo "   To kill the existing process: kill \$(lsof -t -i :${PROXY_PORT})"
  exit 1
fi

if [ ! -f /home/node/.mitmproxy/mitmproxy-ca-cert.pem ]; then
  echo "⚠  mitmproxy CA not found. Restoring from backup..."
  mkdir -p /home/node/.mitmproxy
  cp /usr/local/share/mitmproxy-ca-backup/* /home/node/.mitmproxy/ 2>/dev/null || {
    echo "✗  Failed to restore CA. Run: timeout 3 mitmdump || true"
    exit 1
  }
  echo "✓  CA restored."
fi

MITMWEB_CMD=(
  mitmweb
  --listen-port "$PROXY_PORT"
  --web-port "$WEB_PORT"
  --web-host "0.0.0.0"
  --set "confdir=/home/node/.mitmproxy"
  --set "flow_detail=0"
  --set "web_password=${WEB_PASSWORD}"
  --no-web-open-browser
)

if [ -n "$FLOW_FILE" ]; then
  MITMWEB_CMD+=(--save-stream-file "$FLOW_FILE")
  echo "  Flows will be saved to: $FLOW_FILE"
fi

if [ "$ANALYZE" = true ]; then
  MITMWEB_CMD+=(-s "/workspaces/ai-agent-proxy-lab-codespace/analyzer/backend/addon.py")
  echo "  Flow capture enabled: /home/node/.agent-analyzer/flows.db"
  uvicorn --app-dir /workspaces/ai-agent-proxy-lab-codespace/analyzer/backend server:app \
    --host 0.0.0.0 --port "$API_PORT" --log-level warning &
  API_PID=$!
  trap "kill $API_PID 2>/dev/null || true" EXIT
fi

echo ""
echo "🔍 Starting mitmweb..."
echo "   Proxy listening on:  127.0.0.1:${PROXY_PORT}"
echo ""
if [ -n "$CODESPACES" ]; then
  echo "   mitmweb UI (auth): ${WEB_AUTH_URL}"
  echo "   (If port ${WEB_PORT} didn't auto-forward, open the Ports tab)"
else
  echo "   mitmweb UI (auth): ${WEB_AUTH_URL}"
fi
echo "   (token persisted at ${TOKEN_FILE}; override with MITMWEB_PASSWORD)"
echo ""
echo "   In another terminal, run one of:"
echo "     claude-via-proxy"
echo "     gemini-via-proxy"
echo "     codex-via-proxy"
echo "     copilot-via-proxy"
echo "     opencode-via-proxy"
echo ""
echo "   Or manually: source proxy-on && claude"
echo ""
echo "   Press Ctrl+C to stop."
echo ""

exec "${MITMWEB_CMD[@]}"
