#!/bin/sh
export HTTP_PROXY=http://127.0.0.1:8080
export HTTPS_PROXY=http://127.0.0.1:8080
export http_proxy=http://127.0.0.1:8080
export https_proxy=http://127.0.0.1:8080
export NO_PROXY=localhost,127.0.0.1
export no_proxy=localhost,127.0.0.1

echo "✓ Proxy ON — traffic routes through mitmproxy at :8080"
if [ -n "$CODESPACES" ]; then
  echo "  mitmweb UI: https://${CODESPACE_NAME}-8081.app.github.dev"
else
  echo "  mitmweb UI: http://localhost:8081"
fi
echo "  Make sure mitmweb is running: start-proxy (or mitmweb -p 8080 --web-port 8081 --web-host 0.0.0.0)"
