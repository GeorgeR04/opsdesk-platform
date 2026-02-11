#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

NS="${NAMESPACE:-opsdesk}"
JOB="${MIGRATE_JOB_NAME:-opsdesk-migrate}"
TIMEOUT="${MIGRATE_TIMEOUT:-180s}"

[[ -f .opsdesk_version ]] || die "Missing .opsdesk_version (run: make build)"
V="$(cat .opsdesk_version)"

# Trick: safely inject "$" into the YAML without Bash trying to expand $CFG locally
DOLLAR='$'

log "Run DB migrations via Job (ns=${NS}) image=opsdesk/api:${V}"

kubectl -n "${NS}" delete job "${JOB}" --ignore-not-found >/dev/null 2>&1 || true

cat <<YAML | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB}
  namespace: ${NS}
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: opsdesk/api:${V}
          imagePullPolicy: IfNotPresent
          workingDir: /app
          envFrom:
            - configMapRef:
                name: opsdesk-config
            - secretRef:
                name: opsdesk-secrets
          command: ["sh","-lc"]
          args:
            - 'set -e; cd /app; CFG="`find /app -maxdepth 4 -name alembic.ini -print -quit 2>/dev/null || true`"; echo "[migrate] CFG=${DOLLAR}CFG"; if [ -n "${DOLLAR}CFG" ]; then python -m alembic -c "${DOLLAR}CFG" upgrade head; else python -m alembic upgrade head; fi'
YAML

log "Wait for job completion (timeout=${TIMEOUT})"
kubectl -n "${NS}" wait --for=condition=complete "job/${JOB}" --timeout="${TIMEOUT}" \
  || { kubectl -n "${NS}" logs "job/${JOB}" --tail=200 || true; die "Migration job failed"; }

log "Migration logs (tail)"
kubectl -n "${NS}" logs "job/${JOB}" --tail=200 || true

log "Migrations OK ✅"
