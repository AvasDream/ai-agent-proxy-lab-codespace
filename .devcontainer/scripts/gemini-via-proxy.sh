#!/bin/bash
# Launch Gemini CLI with HTTP(S) traffic routed through mitmproxy.
# All arguments are passed through to gemini.

source /usr/local/bin/_proxy-common.sh
proxy_preflight "gemini" || exit 1

echo "🔍 Gemini CLI → mitmproxy (filter: ~d generativelanguage.googleapis.com)"
exec gemini "$@"
