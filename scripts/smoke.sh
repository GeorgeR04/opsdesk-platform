#!/usr/bin/env bash
set -euo pipefail
source scripts/lib.sh

log "Pods (opsdesk)"
kubectl -n opsdesk get pods -o wide

log "Ingress"
kubectl -n opsdesk get ingress

log "HTTP checks (TLS self-signed so -k)"
curl -skSLf https://api.opsdesk.local/health | jq .
curl -skSLf https://api.opsdesk.local/ready  | jq .
curl -skSLf https://api.opsdesk.local/api/changes/ | jq .

log "Smoke OK"
