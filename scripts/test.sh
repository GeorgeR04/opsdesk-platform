#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

export DATABASE_URL="${DATABASE_URL:-sqlite+pysqlite:///./opsdesk_test.db}"

log "Python tests (pytest)"

rm -rf .venv-ci
python3 -m venv .venv-ci
# shellcheck disable=SC1091
source .venv-ci/bin/activate

# Pin pip < 26 (plus tolérant sur certains cas editables/monorepo)
python -m pip install -U "pip<26" wheel
python -m pip --version

log "Install API (editable + dev extras)"
python -m pip install -e "apps/api[dev]" -vv

log "Install Worker (editable + dev extras)"
python -m pip install -e "apps/worker[dev]" -vv

log "pip check"
python -m pip check

log "Run tests"
pytest -q apps/api/tests apps/worker/tests

log "Frontend tests (vitest via docker build)"
docker build \
  -f infra/ci/frontend.test.Dockerfile \
  -t opsdesk/frontend-test:local \
  .
