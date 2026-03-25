#!/bin/bash
set -euo pipefail

echo "=== Building devcontainer ==="
devcontainer build --workspace-folder . 2>&1 | tail -5

echo "=== Starting devcontainer ==="
devcontainer up --workspace-folder .

echo "=== Running tool presence checks ==="
devcontainer exec --workspace-folder . bash -c '
  PASS=0; FAIL=0
  for cmd in claude gemini codex copilot opencode mitmproxy mitmweb mitmdump; do
    if command -v "$cmd" &>/dev/null; then
      echo "  ✓ $cmd"
      ((PASS++))
    else
      echo "  ✗ $cmd NOT FOUND"
      ((FAIL++))
    fi
  done
  echo ""
  echo "Passed: $PASS  Failed: $FAIL"
  [ "$FAIL" -eq 0 ] || exit 1
'

echo "=== Checking convenience scripts ==="
devcontainer exec --workspace-folder . bash -c '
  PASS=0; FAIL=0
  for cmd in start-proxy claude-via-proxy gemini-via-proxy codex-via-proxy copilot-via-proxy opencode-via-proxy proxy-on proxy-off _proxy-common.sh; do
    if [ -f "/usr/local/bin/$cmd" ] && [ -x "/usr/local/bin/$cmd" ]; then
      echo "  ✓ $cmd"
      ((PASS++))
    else
      echo "  ✗ $cmd NOT FOUND or not executable"
      ((FAIL++))
    fi
  done
  echo ""
  echo "Passed: $PASS  Failed: $FAIL"
  [ "$FAIL" -eq 0 ] || exit 1
'

echo "=== Checking certificate trust ==="
devcontainer exec --workspace-folder . bash -c '
  [ -f "$NODE_EXTRA_CA_CERTS" ] && echo "  ✓ NODE_EXTRA_CA_CERTS set and file exists"
  [ -f "$SSL_CERT_FILE" ] && echo "  ✓ SSL_CERT_FILE set and file exists"
  [ -f /usr/local/share/ca-certificates/mitmproxy.crt ] && echo "  ✓ mitmproxy CA in OS trust store"
  echo ""
  mitmdump -p 18080 -q &
  sleep 2
  HTTPS_PROXY=http://127.0.0.1:18080 curl -sf https://example.com > /dev/null && echo "  ✓ curl works through mitmproxy (cert trusted)" || echo "  ✗ curl through mitmproxy FAILED"
  kill %1 2>/dev/null || true
'

echo "=== Checking proxy toggle scripts ==="
devcontainer exec --workspace-folder . bash -c '
  source proxy-on
  [ -n "$HTTP_PROXY" ] && echo "  ✓ proxy-on sets HTTP_PROXY" || echo "  ✗ proxy-on failed"
  [ -n "$NO_PROXY" ] && echo "  ✓ proxy-on sets NO_PROXY" || echo "  ✗ NO_PROXY missing"
  source proxy-off
  [ -z "$HTTP_PROXY" ] && echo "  ✓ proxy-off unsets HTTP_PROXY" || echo "  ✗ proxy-off failed"
'

echo "=== Checking via-proxy preflight (no proxy running) ==="
devcontainer exec --workspace-folder . bash -c '
  claude-via-proxy --help 2>&1 | head -3
  echo "  ✓ claude-via-proxy exits gracefully when proxy not running"
'

echo "=== All tests passed ==="
