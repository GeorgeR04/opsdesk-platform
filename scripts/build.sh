#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

V="$(version)"
log "Building images tag=${V}"

docker build -t opsdesk/frontend:${V} apps/frontend
docker build -t opsdesk/api:${V} apps/api
docker build -t opsdesk/worker:${V} apps/worker

echo "${V}" > .opsdesk_version
log "Saved version to .opsdesk_version"
