#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

VALIDATE_ONLY="false"
if [[ "${1:-}" == "--validate-only" ]]; then
  VALIDATE_ONLY="true"; shift
fi

ENV="${1:-dev}"
OVERLAY="k8s/overlays/${ENV}"

[[ -d "${OVERLAY}" ]] || die "Overlay not found: ${OVERLAY}"
[[ -f .opsdesk_version ]] || die "Missing .opsdesk_version. Run: make build"
V="$(cat .opsdesk_version)"

log "Deploy ENV=${ENV} VERSION=${V}"

log "Set images in overlay=${ENV}"
pushd "${OVERLAY}" >/dev/null
kustomize edit set image \
  OPSDESK_API_IMAGE=opsdesk/api:${V} \
  OPSDESK_WORKER_IMAGE=opsdesk/worker:${V} \
  OPSDESK_FRONTEND_IMAGE=opsdesk/frontend:${V}
popd >/dev/null

log "Render manifests"
kustomize build "${OVERLAY}" > /tmp/opsdesk.rendered.yaml

log "Client-side validation (kubectl --dry-run=client)"
kubectl apply --dry-run=client -f /tmp/opsdesk.rendered.yaml >/dev/null

if [[ "${VALIDATE_ONLY}" == "true" ]]; then
  log "Validation OK (dry-run only)."
  exit 0
fi

# --- Secrets (Jour 2) ---
if [[ -x "./scripts/secrets.sh" ]]; then
  log "Apply secrets (opsdesk-secrets)"
  ./scripts/secrets.sh
else
  log "secrets.sh not found/executable (skipping)"
fi

log "Apply manifests"
kubectl apply -f /tmp/opsdesk.rendered.yaml

# --- Wait deps if they exist (Postgres/Redis) ---
log "Wait for Postgres/Redis (if deployed)"
if kubectl -n opsdesk get pods -l app=postgres >/dev/null 2>&1; then
  kubectl -n opsdesk wait --for=condition=ready pod -l app=postgres --timeout=180s \
    || die "Postgres not ready. Check: kubectl -n opsdesk get pods; kubectl -n opsdesk logs -l app=postgres"
else
  log "Postgres not found (skip wait)"
fi

if kubectl -n opsdesk get pods -l app=redis >/dev/null 2>&1; then
  kubectl -n opsdesk wait --for=condition=ready pod -l app=redis --timeout=180s \
    || die "Redis not ready. Check: kubectl -n opsdesk get pods; kubectl -n opsdesk logs -l app=redis"
else
  log "Redis not found (skip wait)"
fi

# --- Migrations (Jour 2) ---
if [[ -x "./scripts/migrate.sh" ]]; then
  log "Run DB migrations (Alembic job)"
  ./scripts/migrate.sh || die "Migration failed. Check job logs in opsdesk namespace."
else
  log "migrate.sh not found/executable (skipping)"
fi

# --- Rollouts (apps) ---
log "Wait for rollouts (api/frontend/worker)"
kubectl -n opsdesk rollout status deploy/opsdesk-api --timeout=180s \
  || die "API rollout failed. Check: kubectl -n opsdesk describe deploy/opsdesk-api; kubectl -n opsdesk logs deploy/opsdesk-api"

kubectl -n opsdesk rollout status deploy/opsdesk-frontend --timeout=180s \
  || die "Frontend rollout failed. Check: kubectl -n opsdesk describe deploy/opsdesk-frontend; kubectl -n opsdesk logs deploy/opsdesk-frontend"

kubectl -n opsdesk rollout status deploy/opsdesk-worker --timeout=180s \
  || die "Worker rollout failed. Check: kubectl -n opsdesk describe deploy/opsdesk-worker; kubectl -n opsdesk logs deploy/opsdesk-worker"

log "Deploy OK "
