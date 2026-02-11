#!/usr/bin/env bash
set -euo pipefail

# OpsDesk - Trivy image scan
# - Default: fail on HIGH/CRITICAL
# - Default: ignore "unfixed" vulns (no patch available yet), so CI doesn't block on Debian/OS issues
#
# Usage:
#   make scan
#   TRIVY_IGNORE_UNFIXED=0 make scan      # strict mode (fail even if no fix exists)
#   TRIVY_SCANNERS=vuln make scan         # (default) faster; disables secret scanning
#   TRIVY_IGNORE_FILE=.trivyignore make scan

source scripts/lib.sh

[[ -f .opsdesk_version ]] || die "Run make build first"
V="$(cat .opsdesk_version)"

SEVERITIES="${TRIVY_SEVERITIES:-HIGH,CRITICAL}"
EXIT_CODE="${TRIVY_EXIT_CODE:-1}"
SCANNERS="${TRIVY_SCANNERS:-vuln}"

# 1 = recommended for local/dev (don't block on CVEs with no fixed version published)
# 0 = strict mode
IGNORE_UNFIXED="${TRIVY_IGNORE_UNFIXED:-1}"

EXTRA_ARGS=()
if [[ "${IGNORE_UNFIXED}" == "1" ]]; then
  EXTRA_ARGS+=(--ignore-unfixed)
fi

if [[ -n "${TRIVY_IGNORE_FILE:-}" ]]; then
  EXTRA_ARGS+=(--ignorefile "${TRIVY_IGNORE_FILE}")
fi

if [[ -n "${TRIVY_TIMEOUT:-}" ]]; then
  EXTRA_ARGS+=(--timeout "${TRIVY_TIMEOUT}")
fi

if [[ -n "${TRIVY_CACHE_DIR:-}" ]]; then
  EXTRA_ARGS+=(--cache-dir "${TRIVY_CACHE_DIR}")
fi

TRIVY_ARGS=(image --severity "${SEVERITIES}" --exit-code "${EXIT_CODE}" --scanners "${SCANNERS}" "${EXTRA_ARGS[@]}")

log "Trivy scan (${SEVERITIES}) tag=${V} ignore_unfixed=${IGNORE_UNFIXED} scanners=${SCANNERS}"

images=(
  "opsdesk/api"
  "opsdesk/worker"
  "opsdesk/frontend"
)

for img in "${images[@]}"; do
  log "Scan ${img}:${V}"
  trivy "${TRIVY_ARGS[@]}" "${img}:${V}"
done
