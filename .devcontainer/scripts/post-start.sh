#!/bin/bash

if [ ! -f /home/node/.mitmproxy/mitmproxy-ca-cert.pem ]; then
  echo "Restoring mitmproxy CA from backup..."
  mkdir -p /home/node/.mitmproxy
  cp /usr/local/share/mitmproxy-ca-backup/* /home/node/.mitmproxy/ 2>/dev/null || true
fi

if [ ! -f /home/node/.codex/config.toml ]; then
  mkdir -p /home/node/.codex
  cp /usr/local/share/codex-config-backup/config.toml /home/node/.codex/ 2>/dev/null || true
fi

echo ""
echo "🔍 agent-analyzer-devcontainer ready!"
echo ""
echo "  Quick start:"
echo "    Terminal 1:  start-proxy"
echo "    Terminal 2:  claude-via-proxy   (or gemini / codex / copilot / opencode)"
echo ""
echo "  Manual mode:"
echo "    Terminal 1:  mitmweb -p 8080 --web-port 8081 --web-host 0.0.0.0"
echo "    Terminal 2:  source proxy-on && claude"
echo ""
echo "  Available commands:"
echo "    start-proxy         — Start mitmweb (run once)"
echo "    claude-via-proxy    — Claude Code through proxy"
echo "    gemini-via-proxy    — Gemini CLI through proxy"
echo "    codex-via-proxy     — Codex CLI through proxy"
echo "    copilot-via-proxy   — GitHub Copilot CLI through proxy"
echo "    opencode-via-proxy  — OpenCode through proxy"
echo "    source proxy-on     — Set proxy env vars manually"
echo "    source proxy-off    — Unset proxy env vars"
echo "    test-proxy          — Run verification checks"
echo ""
TOKEN_FILE="/home/node/.mitmproxy/mitmweb-token"
MITMWEB_TOKEN=""
if [ -f "$TOKEN_FILE" ]; then
  MITMWEB_TOKEN="$(cat "$TOKEN_FILE")"
fi

if [ -n "$CODESPACES" ]; then
  if [ -n "$MITMWEB_TOKEN" ]; then
    echo "  mitmweb UI: https://${CODESPACE_NAME}-8081.app.github.dev/?token=${MITMWEB_TOKEN}"
  else
    echo "  mitmweb UI: https://${CODESPACE_NAME}-8081.app.github.dev"
  fi
  echo "  (If port 8081 didn't auto-forward, open the Ports tab and forward it manually)"
else
  if [ -n "$MITMWEB_TOKEN" ]; then
    echo "  mitmweb UI: http://localhost:8081/?token=${MITMWEB_TOKEN}"
  else
    echo "  mitmweb UI: http://localhost:8081"
  fi
fi
echo ""
