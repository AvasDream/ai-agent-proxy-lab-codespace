#!/bin/bash
set -e
echo "=== Testing mitmproxy interception ==="

mitmdump -p 8080 --set flow_detail=0 -w /tmp/test-flows &
MITM_PID=$!
sleep 2

export HTTP_PROXY=http://127.0.0.1:8080
export HTTPS_PROXY=http://127.0.0.1:8080

curl -s https://httpbin.org/get > /dev/null 2>&1 || echo "Note: httpbin may be unreachable (expected in restricted networks)"

echo ""
echo "--- Tool binaries ---"
for cmd in claude gemini codex copilot opencode; do
  printf "  %-12s" "$cmd:"
  if command -v "$cmd" &>/dev/null; then
    echo "✓ $(command -v "$cmd")"
  else
    echo "✗ NOT FOUND"
  fi
done

echo ""
echo "--- Proxy infrastructure ---"
for cmd in mitmproxy mitmweb mitmdump; do
  printf "  %-12s" "$cmd:"
  if command -v "$cmd" &>/dev/null; then
    echo "✓ $(command -v "$cmd")"
  else
    echo "✗ NOT FOUND"
  fi
done

echo ""
echo "--- Convenience scripts ---"
for cmd in start-proxy claude-via-proxy gemini-via-proxy codex-via-proxy copilot-via-proxy opencode-via-proxy proxy-on proxy-off test-proxy; do
  printf "  %-22s" "$cmd:"
  if [ -f "/usr/local/bin/$cmd" ]; then
    echo "✓"
  else
    echo "✗ NOT FOUND"
  fi
done

echo ""
echo "--- Certificate trust ---"
printf "  %-28s" "NODE_EXTRA_CA_CERTS:"
[ -f "$NODE_EXTRA_CA_CERTS" ] && echo "✓ ($NODE_EXTRA_CA_CERTS)" || echo "✗ NOT SET"
printf "  %-28s" "CODEX_CA_CERTIFICATE:"
[ -f "$CODEX_CA_CERTIFICATE" ] && echo "✓ ($CODEX_CA_CERTIFICATE)" || echo "✗ NOT SET"
printf "  %-28s" "SSL_CERT_FILE:"
[ -f "$SSL_CERT_FILE" ] && echo "✓ ($SSL_CERT_FILE)" || echo "✗ NOT SET"
printf "  %-28s" "mitmproxy CA in OS store:"
[ -f /usr/local/share/ca-certificates/mitmproxy.crt ] && echo "✓" || echo "✗"

echo ""
echo "--- Shared helper ---"
printf "  %-28s" "_proxy-common.sh:"
[ -f "/usr/local/bin/_proxy-common.sh" ] && echo "✓" || echo "✗ NOT FOUND"

echo ""
echo "--- Permission checks ---"
printf "  %-28s" "sudo NOPASSWD for node:"
sudo -n true >/dev/null 2>&1 && echo "✓" || echo "✗"
for dir in /home/node/.gemini /home/node/.config/opencode /home/node/.copilot; do
  printf "  %-28s" "${dir}:"
  mkdir -p "$dir" 2>/dev/null || true
  [ -w "$dir" ] && echo "✓ writable" || echo "✗ not writable"
done

kill "$MITM_PID" 2>/dev/null || true
echo ""
echo "=== All checks complete ==="
