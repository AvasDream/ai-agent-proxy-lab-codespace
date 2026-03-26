from classifier import classify


def test_classifies_ai():
    assert classify("api.anthropic.com") == ("ai", "anthropic", "claude")


def test_classifies_auth():
    assert classify("auth.openai.com") == ("auth", None, None)


def test_classifies_other():
    assert classify("example.com") == ("other", None, None)
