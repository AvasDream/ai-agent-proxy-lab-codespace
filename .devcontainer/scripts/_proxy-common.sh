#!/bin/bash
# Shared helper for *-via-proxy scripts. Source this, don't execute it.

PROXY_PORT="${PROXY_PORT:-8080}"
PROXY_ADDR="http://127.0.0.1:${PROXY_PORT}"

proxy_preflight() {
  local tool_name="$1"

  # Check if mitmproxy is listening
  if ! ss -tln 2>/dev/null | grep -q ":${PROXY_PORT} " && \
     ! curl -sf --max-time 1 -o /dev/null "http://127.0.0.1:${PROXY_PORT}" 2>/dev/null; then
    echo "✗  mitmproxy is not running on port ${PROXY_PORT}."
    echo "   Start it first:  start-proxy"
    echo ""
    echo "   Or run ${tool_name} without proxy:  ${tool_name}"
    return 1
  fi

  # Set proxy env vars
  export HTTP_PROXY="$PROXY_ADDR"
  export HTTPS_PROXY="$PROXY_ADDR"
  export http_proxy="$PROXY_ADDR"
  export https_proxy="$PROXY_ADDR"
  export NO_PROXY="localhost,127.0.0.1"
  export no_proxy="localhost,127.0.0.1"
}
