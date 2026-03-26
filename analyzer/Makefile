.PHONY: install test test-backend test-frontend test-e2e lint

install:
	cd backend && pip install -r requirements-dev.txt --break-system-packages
	cd frontend && npm ci

test: test-backend test-frontend

test-backend:
	cd backend && python -m pytest -v --tb=short

test-frontend:
	cd frontend && npx vitest run

test-e2e:
	bash e2e/test_e2e.sh

lint:
	cd backend && python -m py_compile db.py classifier.py addon.py server.py
	cd frontend && npx tsc --noEmit
