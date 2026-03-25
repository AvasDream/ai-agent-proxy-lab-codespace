#!/bin/bash
# Launch Codex CLI with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to codex.

source /usr/local/bin/_proxy-common.sh
ensure_writable_dirs /home/node/.codex || exit 1

if [ -z "${OPENAI_API_KEY:-}" ] && [ ! -f /home/node/.codex/auth.json ]; then
  echo "⚠  No Codex auth found at /home/node/.codex/auth.json."
  echo "   Authenticate first WITHOUT proxy, then retry:"
  echo "     codex login --device-auth"
  echo "     codex-via-proxy"
  echo ""
  echo "   Or set OPENAI_API_KEY to skip OAuth:"
  echo "     export OPENAI_API_KEY=sk-..."
  echo "     codex-via-proxy"
  exit 1
fi

export CODEX_CA_CERTIFICATE="${CODEX_CA_CERTIFICATE:-/home/node/.mitmproxy/mitmproxy-ca-cert.pem}"
proxy_preflight "codex" || exit 1

echo "🔍 Codex CLI → mitmproxy (filter: ~d api.openai.com)"
exec codex "$@"
