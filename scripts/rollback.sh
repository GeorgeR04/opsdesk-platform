#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

log "Rollback (rollout undo)"
kubectl -n opsdesk rollout undo deploy/opsdesk-api
kubectl -n opsdesk rollout undo deploy/opsdesk-frontend
kubectl -n opsdesk rollout undo deploy/opsdesk-worker

log "Wait after rollback"
kubectl -n opsdesk rollout status deploy/opsdesk-api --timeout=180s
kubectl -n opsdesk rollout status deploy/opsdesk-frontend --timeout=180s
kubectl -n opsdesk rollout status deploy/opsdesk-worker --timeout=180s
