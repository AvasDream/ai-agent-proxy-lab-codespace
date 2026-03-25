#!/bin/bash
# Launch Claude Code with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to claude.

source /usr/local/bin/_proxy-common.sh
proxy_preflight "claude" || exit 1

echo "🔍 Claude Code → mitmproxy (filter: ~d api.anthropic.com)"
exec claude "$@"
