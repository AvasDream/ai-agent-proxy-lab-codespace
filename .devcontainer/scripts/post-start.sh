#!/bin/bash

set -e

ensure_node_owned_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    sudo mkdir -p "$dir"
  fi
  sudo chown -R node:node "$dir"
}

# Fix ownership for persisted volumes/directories that can be root-owned in Codespaces.
ensure_node_owned_dir /home/node/.mitmproxy
ensure_node_owned_dir /home/node/.claude
ensure_node_owned_dir /home/node/.codex
ensure_node_owned_dir /home/node/.gemini
ensure_node_owned_dir /home/node/.copilot
ensure_node_owned_dir /home/node/.config
ensure_node_owned_dir /home/node/.config/gh
ensure_node_owned_dir /home/node/.config/opencode
ensure_node_owned_dir /home/node/.agent-analyzer
ensure_node_owned_dir /commandhistory

seed_history_file() {
  local history_file="$1"
  shift
  touch "$history_file"
  local ts
  ts=$(date +%s)
  for cmd in "$@"; do
    if ! grep -Fq "$cmd" "$history_file"; then
      if [[ "$history_file" == *.zsh_history ]]; then
        # Zsh extended history format (compatible with SHARE_HISTORY)
        echo ": ${ts}:0;${cmd}" >> "$history_file"
      else
        echo "$cmd" >> "$history_file"
      fi
    fi
  done
}

seed_shell_history() {
  local commands=(
    "start-proxy"
    "start-analyzer"
    "tmux attach -t analyzer"
    "claude-via-proxy"
    "gemini-via-proxy"
    "codex-via-proxy"
    "copilot-via-proxy"
    "opencode-via-proxy"
    "source proxy-on"
    "source proxy-off"
    "test-proxy"
  )

  seed_history_file /home/node/.bash_history "${commands[@]}"
  seed_history_file /home/node/.zsh_history "${commands[@]}"
  if [ -d /commandhistory ]; then
    seed_history_file /commandhistory/.bash_history "${commands[@]}"
    seed_history_file /commandhistory/.zsh_history "${commands[@]}"
  fi

  sudo chown node:node /home/node/.bash_history /home/node/.zsh_history
  if [ -f /commandhistory/.bash_history ]; then
    sudo chown node:node /commandhistory/.bash_history
  fi
  if [ -f /commandhistory/.zsh_history ]; then
    sudo chown node:node /commandhistory/.zsh_history
  fi
}

seed_shell_history

if [ ! -f /home/node/.mitmproxy/mitmproxy-ca-cert.pem ]; then
  echo "Restoring mitmproxy CA from backup..."
  cp /usr/local/share/mitmproxy-ca-backup/* /home/node/.mitmproxy/ 2>/dev/null || true
fi

if [ ! -f /home/node/.codex/config.toml ]; then
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
echo "    start-proxy         — Start mitmweb (run once)
    start-analyzer      — Start full analyzer stack (tmux)"
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
