#!/bin/bash
set -e

# --- Configuration ---
SESSION="analyzer"
export PROXY_PORT="${PROXY_PORT:-8080}"
export WEB_PORT="${WEB_PORT:-8081}"
export API_PORT="${API_PORT:-5555}"
export FRONTEND_PORT="${FRONTEND_PORT:-5173}"
ANALYZER_DIR="${ANALYZER_DIR:-/workspaces/ai-agent-proxy-lab-codespace/analyzer}"

# --- Kill existing session for clean start ---
tmux kill-session -t "$SESSION" 2>/dev/null || true

# --- Create detached session with first window (api) ---
tmux new-session -d -s "$SESSION" -n "api" -x "$(tput cols)" -y "$(tput lines)"

tmux send-keys -t "${SESSION}:api" \
  "export PROXY_PORT=${PROXY_PORT} WEB_PORT=${WEB_PORT} API_PORT=${API_PORT} FRONTEND_PORT=${FRONTEND_PORT} && uvicorn --app-dir '${ANALYZER_DIR}/backend' server:app --host 0.0.0.0 --port ${API_PORT} --log-level warning" Enter

# --- Window 1: proxy (mitmweb) ---
tmux new-window -t "$SESSION" -n "proxy"
tmux send-keys -t "${SESSION}:proxy" \
  "export PROXY_PORT=${PROXY_PORT} WEB_PORT=${WEB_PORT} API_PORT=${API_PORT} FRONTEND_PORT=${FRONTEND_PORT} && mitmweb --listen-port ${PROXY_PORT} --web-port ${WEB_PORT} --web-host 0.0.0.0 --no-web-open-browser --set 'confdir=/home/node/.mitmproxy' --set 'flow_detail=0' -s '${ANALYZER_DIR}/backend/addon.py'" Enter

# --- Window 2: frontend (vite) ---
tmux new-window -t "$SESSION" -n "frontend"
tmux send-keys -t "${SESSION}:frontend" \
  "export PROXY_PORT=${PROXY_PORT} WEB_PORT=${WEB_PORT} API_PORT=${API_PORT} FRONTEND_PORT=${FRONTEND_PORT} && cd '${ANALYZER_DIR}/frontend' && npx vite --host 0.0.0.0 --port ${FRONTEND_PORT}" Enter

# --- Select the frontend window and attach ---
tmux select-window -t "${SESSION}:frontend"

echo "Starting analyzer (tmux session: ${SESSION})"
echo "  API:      http://localhost:${API_PORT}"
echo "  Proxy:    localhost:${PROXY_PORT}"
echo "  Web UI:   http://localhost:${WEB_PORT}"
echo "  Frontend: http://localhost:${FRONTEND_PORT}"
echo ""
echo "Tip: Ctrl+a d to detach, then 'tmux attach -t ${SESSION}' to reattach"
echo ""

exec tmux attach -t "$SESSION"
