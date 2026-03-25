#!/bin/bash
# Launch OpenCode with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to opencode.

source /usr/local/bin/_proxy-common.sh
proxy_preflight "opencode" || exit 1

echo "🔍 OpenCode → mitmproxy (check your configured provider's domain)"
exec opencode "$@"
