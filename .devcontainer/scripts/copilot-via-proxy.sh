#!/bin/bash
# Launch GitHub Copilot CLI with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to copilot.

source /usr/local/bin/_proxy-common.sh
proxy_preflight "copilot" || exit 1

echo "🔍 Copilot CLI → mitmproxy (filter: ~d api.githubcopilot.com)"
exec copilot "$@"
