#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

mkdir -p .secrets
ENVFILE=".secrets/opsdesk.env"

if [[ ! -f "${ENVFILE}" ]]; then
  log "Generating .secrets/opsdesk.env (local only)"
  JWT="$(openssl rand -hex 32)"
  DBPASS="$(openssl rand -hex 16)"
  cat > "${ENVFILE}" <<EOF
JWT_SECRET=${JWT}
POSTGRES_DB=opsdesk
POSTGRES_USER=opsdesk
POSTGRES_PASSWORD=${DBPASS}
DATABASE_URL=postgresql+psycopg://opsdesk:${DBPASS}@postgres.opsdesk.svc.cluster.local:5432/opsdesk
REDIS_URL=redis://redis.opsdesk.svc.cluster.local:6379/0
CELERY_BROKER_URL=redis://redis.opsdesk.svc.cluster.local:6379/0
CELERY_RESULT_BACKEND=redis://redis.opsdesk.svc.cluster.local:6379/0
EOF
fi

log "Create/Update secret opsdesk-secrets"
kubectl -n opsdesk create secret generic opsdesk-secrets \
  --from-env-file="${ENVFILE}" \
  --dry-run=client -o yaml | kubectl apply -f -
