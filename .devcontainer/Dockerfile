FROM node:22-bookworm

ARG TZ=Europe/Zurich
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=${TZ}

RUN apt-get update && apt-get install -y --no-install-recommends \
  python3 python3-pip python3-venv \
  ca-certificates curl wget git jq tmux \
  less procps sudo fzf zsh nano vim \
  iptables ipset iproute2 dnsutils \
  unzip gnupg2 lsof openssl \
  && rm -rf /var/lib/apt/lists/*

RUN echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node && chmod 0440 /etc/sudoers.d/node

RUN chsh -s /usr/bin/zsh node

RUN pip install --break-system-packages mitmproxy

RUN mkdir -p /home/node/.mitmproxy /usr/local/share/npm-global && \
    chown -R node:node /home/node/.mitmproxy /usr/local/share/npm-global

USER node
RUN timeout 3 mitmdump || true

USER root
RUN cp /home/node/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy.crt && \
    update-ca-certificates

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV NODE_EXTRA_CA_CERTS=/home/node/.mitmproxy/mitmproxy-ca-cert.pem
ENV CODEX_CA_CERTIFICATE=/home/node/.mitmproxy/mitmproxy-ca-cert.pem
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

USER node
RUN npm install -g @anthropic-ai/claude-code@latest && \
    npm install -g @google/gemini-cli && \
    npm install -g @openai/codex && \
    npm install -g @github/copilot && \
    npm install -g opencode-ai

USER root
COPY scripts/setup-codex-config.sh /tmp/setup-codex-config.sh
RUN chmod +x /tmp/setup-codex-config.sh && /tmp/setup-codex-config.sh && rm /tmp/setup-codex-config.sh

USER root
RUN cp -r /home/node/.mitmproxy /usr/local/share/mitmproxy-ca-backup && \
    mkdir -p /usr/local/share/codex-config-backup && \
    cp /home/node/.codex/config.toml /usr/local/share/codex-config-backup/ && \
    chown -R node:node /usr/local/share/mitmproxy-ca-backup /usr/local/share/codex-config-backup

COPY scripts/proxy-on.sh /usr/local/bin/proxy-on
COPY scripts/proxy-off.sh /usr/local/bin/proxy-off
COPY scripts/start-proxy.sh /usr/local/bin/start-proxy
COPY scripts/_proxy-common.sh /usr/local/bin/_proxy-common.sh
COPY scripts/claude-via-proxy.sh /usr/local/bin/claude-via-proxy
COPY scripts/gemini-via-proxy.sh /usr/local/bin/gemini-via-proxy
COPY scripts/codex-via-proxy.sh /usr/local/bin/codex-via-proxy
COPY scripts/copilot-via-proxy.sh /usr/local/bin/copilot-via-proxy
COPY scripts/opencode-via-proxy.sh /usr/local/bin/opencode-via-proxy
COPY scripts/post-start.sh /usr/local/bin/post-start.sh
COPY scripts/test-proxy.sh /usr/local/bin/test-proxy

RUN chmod +x /usr/local/bin/proxy-on \
             /usr/local/bin/proxy-off \
             /usr/local/bin/start-proxy \
             /usr/local/bin/_proxy-common.sh \
             /usr/local/bin/claude-via-proxy \
             /usr/local/bin/gemini-via-proxy \
             /usr/local/bin/codex-via-proxy \
             /usr/local/bin/copilot-via-proxy \
             /usr/local/bin/opencode-via-proxy \
             /usr/local/bin/post-start.sh \
             /usr/local/bin/test-proxy && \
    chown node:node /usr/local/bin/proxy-on \
                    /usr/local/bin/proxy-off \
                    /usr/local/bin/start-proxy \
                    /usr/local/bin/_proxy-common.sh \
                    /usr/local/bin/claude-via-proxy \
                    /usr/local/bin/gemini-via-proxy \
                    /usr/local/bin/codex-via-proxy \
                    /usr/local/bin/copilot-via-proxy \
                    /usr/local/bin/opencode-via-proxy \
                    /usr/local/bin/post-start.sh \
                    /usr/local/bin/test-proxy

USER node
