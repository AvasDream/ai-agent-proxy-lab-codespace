#!/bin/bash
set -euo pipefail

mkdir -p /home/node/.mitmproxy
chown -R node:node /home/node/.mitmproxy

su - node -c 'timeout 3 mitmdump || true'

cp /home/node/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt
update-ca-certificates
