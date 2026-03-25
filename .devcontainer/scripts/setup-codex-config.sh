#!/bin/bash
set -euo pipefail

mkdir -p /home/node/.codex
cat > /home/node/.codex/config.toml <<'EOC'
# Disable sandbox in Docker (Landlock not supported)
sandbox_mode = "danger-full-access"
# Keep approval prompts for safety
approval_policy = "on-request"
# TLS trust is configured via environment:
# CODEX_CA_CERTIFICATE=/home/node/.mitmproxy/mitmproxy-ca-cert.pem
EOC

chown -R node:node /home/node/.codex
