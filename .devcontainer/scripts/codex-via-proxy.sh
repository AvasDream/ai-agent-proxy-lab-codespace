#!/bin/bash
# Launch Codex CLI with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to codex.

source /usr/local/bin/_proxy-common.sh
proxy_preflight "codex" || exit 1

echo "🔍 Codex CLI → mitmproxy (filter: ~d api.openai.com)"
exec codex "$@"
