# agent-analyzer

MVP traffic analyzer for mitmproxy flows.

## Run backend tests

```bash
cd analyzer/backend
pip install -r requirements-dev.txt --break-system-packages
pytest -v
```

## Run frontend tests

```bash
cd analyzer/frontend
npm install
npm test
```

## Run e2e

```bash
cd analyzer
make test-e2e
```
