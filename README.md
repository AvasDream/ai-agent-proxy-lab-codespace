# agent-analyzer-devcontainer

A production-ready VS Code devcontainer for intercepting and analyzing AI coding agent HTTP(S) traffic with **mitmproxy**.

This repository gives you a single container that includes:

- `mitmproxy` / `mitmweb`
- Claude Code CLI
- Gemini CLI
- OpenAI Codex CLI
- GitHub Copilot CLI
- OpenCode CLI

It is built to work both:

- locally with VS Code + Docker
- in GitHub Codespaces

---

## Why this project exists

Most AI coding CLIs run over HTTPS and hide their wire-level requests/responses by default. This container provides a clean, repeatable setup where:

1. certificate trust is pre-wired
2. proxy environment configuration is automated
3. each tool has a one-command launcher through the proxy

So you can focus on analysis instead of container plumbing.

---

## Architecture at a glance

```text
┌───────────────────────────────┐
│ claude / gemini / codex / ... │
└──────────────┬────────────────┘
               │ HTTP_PROXY / HTTPS_PROXY
               ▼
        ┌───────────────┐
        │   mitmproxy   │  (port 8080)
        │    mitmweb    │  (port 8081 UI)
        └───────┬───────┘
                ▼
            Internet APIs
```

---

## Quick start (Local: VS Code + Docker)

1. Clone this repository.
2. Open it in VS Code.
3. Run **Dev Containers: Reopen in Container**.
4. Open two terminals in the container:

```bash
# Terminal 1
start-proxy

# Terminal 2
claude-via-proxy
```

Then open the auth URL printed by `start-proxy` (it includes a required `?token=...` query string).
The devcontainer uses `zsh` as the default shell for the `node` user and VS Code integrated terminal.

---

## Quick start (GitHub Codespaces)

1. Click **Code** → **Codespaces** → **Create codespace on main**.
2. Wait for the devcontainer build to finish.
3. In the Codespace terminal:

```bash
# Terminal 1
start-proxy

# Terminal 2
gemini-via-proxy
```

4. Open forwarded port **8081** (mitmweb UI) using the full auth URL printed by `start-proxy`, usually:

```text
https://<your-codespace-name>-8081.app.github.dev/?token=<token>
```

> If 8081 does not auto-forward, use the **Ports** tab and forward it manually.

---

## Day-to-day workflow

### Recommended workflow (simplest)

```bash
# Terminal 1
start-proxy

# Terminal 2
codex-via-proxy
```

### Manual workflow

```bash
# Terminal 1
mitmweb -p 8080 --web-port 8081 --web-host 0.0.0.0

# Terminal 2
source proxy-on
claude

# disable proxy for the current shell
source proxy-off
```

---

## Available commands

| Command | Description |
|---|---|
| `start-proxy` | Start mitmweb in foreground with sane defaults |
| `claude-via-proxy` | Launch Claude Code routed through mitmproxy |
| `gemini-via-proxy` | Launch Gemini CLI routed through mitmproxy |
| `codex-via-proxy` | Launch Codex CLI routed through mitmproxy |
| `copilot-via-proxy` | Launch Copilot CLI routed through mitmproxy |
| `opencode-via-proxy` | Launch OpenCode routed through mitmproxy |
| `source proxy-on` | Set proxy vars in your current shell |
| `source proxy-off` | Unset proxy vars in your current shell |
| `test-proxy` | Verify tool binaries, scripts, and trust wiring |

---

## Authentication and API keys

| Tool | Auth method | Env var |
|---|---|---|
| Claude Code | API key or OAuth | `ANTHROPIC_API_KEY` |
| Gemini CLI | API key or OAuth | `GEMINI_API_KEY` |
| Codex CLI | API key or OAuth | `OPENAI_API_KEY` |
| Copilot CLI | GitHub token/device flow | `COPILOT_GITHUB_TOKEN` or `GH_TOKEN` |
| OpenCode | Provider-specific | provider-specific |

Tip: API keys are usually easier for proxy testing than OAuth callbacks.

---

## mitmweb filter cheatsheet

| Tool | Filter |
|---|---|
| Claude Code | `~d api.anthropic.com` |
| Gemini CLI | `~d generativelanguage.googleapis.com` |
| Codex CLI | `~d api.openai.com \| ~d auth.openai.com` |
| Copilot CLI | `~d api.githubcopilot.com \| ~d copilot-proxy.githubusercontent.com` |
| OpenCode | depends on selected provider |

---

## Advanced usage

### Use custom proxy/web ports

```bash
start-proxy -p 9090 -w 9091
PROXY_PORT=9090 claude-via-proxy
```

### Mitmweb authentication token behavior

- `start-proxy` sets `web_password` so mitmweb UI authentication is required.
- The token is persisted at `/home/node/.mitmproxy/mitmweb-token`.
- The printed UI URL includes `?token=<value>` so browser login is one-click.
- To set your own stable token/password:

```bash
MITMWEB_PASSWORD='your-long-random-secret' start-proxy
```

### Save captured flows to a file

```bash
start-proxy -f /tmp/capture.flow
```

### Run built-in verification inside the container

```bash
test-proxy
```

### Command history is pre-seeded

On container start, the devcontainer seeds `bash`/`zsh` history with:

- `start-proxy`
- `claude-via-proxy`
- `gemini-via-proxy`
- `codex-via-proxy`
- `copilot-via-proxy`
- `opencode-via-proxy`
- `source proxy-on`
- `source proxy-off`
- `test-proxy`

So you can use <kbd>↑</kbd> or reverse-search (`Ctrl+R`) immediately without retyping.

### Host-side full devcontainer test

```bash
bash test/test-devcontainer.sh
```

---

## Troubleshooting

### 1) `*-via-proxy` says mitmproxy is not running

Run `start-proxy` first in another terminal. The wrappers intentionally fail fast when port 8080 is closed.

### 2) TLS/certificate errors

This image pre-installs mitmproxy CA into system trust and sets:

- `NODE_EXTRA_CA_CERTS`
- `SSL_CERT_FILE`
- `REQUESTS_CA_BUNDLE`

If you still see trust errors, run `test-proxy` and verify the CA checks are passing.

### 3) OAuth callbacks fail through proxy

Some OAuth flows are sensitive to interception. Authenticate once without proxy, then retry with `*-via-proxy`, or use API-key auth where available.

### 4) Codex OAuth behind proxy

If Codex OAuth fails, run `codex` once without proxy to log in, then use `codex-via-proxy`.

### 5) Copilot self-signed cert limitation

Some license tiers may not allow self-signed proxy cert interception. Business/Enterprise tends to work better for this scenario.

### 6) Codespaces port forwarding not appearing

- Confirm `start-proxy` is running.
- Forward port 8081 manually in the Ports tab.
- Use the printed URL in terminal output.
- Make sure you include `?token=...` from the printed URL.

### 7) `gemini` / `opencode` EACCES under `~/.gemini` or `~/.config/opencode`

On some Codespaces starts, mounted volumes can come up root-owned. `post-start.sh` now auto-fixes ownership for mounted auth/config dirs on startup.

If your Codespace was created before this fix, run once:

```bash
bash /usr/local/bin/post-start.sh
```

Then retry `gemini`, `gemini-via-proxy`, or `opencode-via-proxy`.

---

## Repository layout

```text
.devcontainer/
├── devcontainer.json
├── Dockerfile
├── scripts/
│   ├── _proxy-common.sh
│   ├── proxy-on.sh
│   ├── proxy-off.sh
│   ├── start-proxy.sh
│   ├── claude-via-proxy.sh
│   ├── gemini-via-proxy.sh
│   ├── codex-via-proxy.sh
│   ├── copilot-via-proxy.sh
│   ├── opencode-via-proxy.sh
│   ├── setup-codex-config.sh
│   ├── post-start.sh
│   └── test-proxy.sh
└── test/
    └── test-devcontainer.sh
```

---

## Notes for open-source publishing

- This project ships no credentials.
- Auth state is persisted in named Docker volumes for convenience.
- The container runs as non-root `node` user by default.
- `codex` sandbox is explicitly disabled in-container for Docker compatibility.

If you publish this repo, consider enabling a prebuilt container image for faster Codespaces startup.
