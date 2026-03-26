"""Domain classifier for agent-analyzer flows."""

AI_DOMAINS: dict[str, tuple[str, str]] = {
    "api.anthropic.com": ("anthropic", "claude"),
    "api.openai.com": ("openai", "codex"),
    "generativelanguage.googleapis.com": ("google", "gemini"),
    "api.githubcopilot.com": ("github", "copilot"),
    "copilot-proxy.githubusercontent.com": ("github", "copilot"),
}

AUTH_DOMAINS: set[str] = {
    "auth.openai.com",
    "accounts.google.com",
    "oauth2.googleapis.com",
    "github.com",
}


def classify(host: str) -> tuple[str, str | None, str | None]:
    """Return (flow_type, provider, agent)."""
    if host in AI_DOMAINS:
        provider, agent = AI_DOMAINS[host]
        return "ai", provider, agent
    if host in AUTH_DOMAINS:
        return "auth", None, None
    return "other", None, None
