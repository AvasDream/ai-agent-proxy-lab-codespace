#!/bin/bash
set -e

PROXY_PORT="${PROXY_PORT:-8080}"
WEB_PORT="${WEB_PORT:-8081}"
FLOW_FILE=""

usage() {
  echo "Usage: start-proxy [OPTIONS]"
  echo ""
  echo "Start mitmweb for HTTP(S) traffic interception."
  echo ""
  echo "Options:"
  echo "  -p, --proxy-port PORT   Proxy listen port (default: 8080)"
  echo "  -w, --web-port PORT     mitmweb UI port (default: 8081)"
  echo "  -f, --flow-file FILE    Save flows to file for later replay"
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
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if ss -tln 2>/dev/null | grep -q ":${PROXY_PORT} " || \
   lsof -i ":${PROXY_PORT}" &>/dev/null; then
  echo "⚠  Port ${PROXY_PORT} is already in use."
  echo "   If mitmweb is already running, open the UI:"
  if [ -n "$CODESPACES" ]; then
    echo "   https://${CODESPACE_NAME}-${WEB_PORT}.app.github.dev"
  else
    echo "   http://localhost:${WEB_PORT}"
  fi
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
  --no-web-open-browser
)

if [ -n "$FLOW_FILE" ]; then
  MITMWEB_CMD+=(--save-stream-file "$FLOW_FILE")
  echo "  Flows will be saved to: $FLOW_FILE"
fi

echo ""
echo "🔍 Starting mitmweb..."
echo "   Proxy listening on:  127.0.0.1:${PROXY_PORT}"
echo ""
if [ -n "$CODESPACES" ]; then
  echo "   mitmweb UI:  https://${CODESPACE_NAME}-${WEB_PORT}.app.github.dev"
  echo "   (If port ${WEB_PORT} didn't auto-forward, open the Ports tab)"
else
  echo "   mitmweb UI:  http://localhost:${WEB_PORT}"
fi
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
