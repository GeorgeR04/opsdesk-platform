#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# OpsDesk bootstrap (Docker Desktop friendly)
#
# What it does:
#   1) Creates namespace "opsdesk"
#   2) Installs ingress-nginx (Helm)
#   3) Installs metrics-server + patches it for Docker Desktop kubelet TLS
#   4) Creates a self-signed TLS secret "opsdesk-tls" in namespace "opsdesk"
#   5) (Optional) Installs observability stack (kube-prometheus-stack, loki, promtail)
#
# Usage:
#   ./bootstrap.sh
#   INSTALL_OBSERVABILITY=1 ./bootstrap.sh
#
# Optional env vars:
#   INGRESS_NGINX_RELEASE=ingress-nginx
#   INGRESS_NGINX_NS=ingress-nginx
#   METRICS_SERVER_MANIFEST_URL=... (defaults to latest)
#   INSTALL_OBSERVABILITY=0|1
#   KPS_VALUES=infra/helm-values/kube-prometheus-stack.values.yaml
#   LOKI_VALUES=infra/helm-values/loki.values.yaml
#   PROMTAIL_VALUES=infra/helm-values/promtail.values.yaml
# ------------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# If you already have a shared logger, keep it. Otherwise, provide a tiny fallback.
if [[ -f "${ROOT_DIR}/scripts/lib.sh" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/scripts/lib.sh"
else
  log() { echo "[$(date +'%H:%M:%S')] $*"; }
fi

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || { echo "ERROR: '${cmd}' not found in PATH"; exit 1; }
}

require_cmd kubectl
require_cmd helm
require_cmd openssl

INGRESS_NGINX_RELEASE="${INGRESS_NGINX_RELEASE:-ingress-nginx}"
INGRESS_NGINX_NS="${INGRESS_NGINX_NS:-ingress-nginx}"

METRICS_SERVER_MANIFEST_URL="${METRICS_SERVER_MANIFEST_URL:-https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml}"

INSTALL_OBSERVABILITY="${INSTALL_OBSERVABILITY:-0}"
KPS_VALUES="${KPS_VALUES:-infra/helm-values/kube-prometheus-stack.values.yaml}"
LOKI_VALUES="${LOKI_VALUES:-infra/helm-values/loki.values.yaml}"
PROMTAIL_VALUES="${PROMTAIL_VALUES:-infra/helm-values/promtail.values.yaml}"

# ------------------------------------------------------------------------------
# 1) Namespace opsdesk
# ------------------------------------------------------------------------------
log "Create namespace opsdesk"
kubectl create ns opsdesk --dry-run=client -o yaml | kubectl apply -f -

# ------------------------------------------------------------------------------
# 2) Helm repos + ingress-nginx
# ------------------------------------------------------------------------------
log "Helm repos (ingress-nginx)"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update >/dev/null

log "Install/upgrade ingress-nginx"
helm upgrade --install "${INGRESS_NGINX_RELEASE}" ingress-nginx/ingress-nginx \
  -n "${INGRESS_NGINX_NS}" --create-namespace

# ------------------------------------------------------------------------------
# 3) metrics-server (HPA / kubectl top) + Docker Desktop TLS patch
# ------------------------------------------------------------------------------
log "Install/upgrade metrics-server (for HPA)"
kubectl apply -f "${METRICS_SERVER_MANIFEST_URL}"

# Wait until the Deployment object exists, then wait for rollout
log "Wait for metrics-server Deployment to be ready"
kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s || true

# Docker Desktop kubelet often uses self-signed / mismatched certs => metrics-server TLS verify fails
# Patch args only if needed (idempotent-ish).
current_args="$(kubectl -n kube-system get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null || true)"

need_patch=0
if echo "${current_args}" | grep -q -- "--kubelet-insecure-tls"; then
  : # already present
else
  need_patch=1
fi

if echo "${current_args}" | grep -q -- "--kubelet-preferred-address-types="; then
  : # already present
else
  need_patch=1
fi

# Heuristic: only auto-patch on Docker Desktop (node name often equals "docker-desktop"),
# but still patch if we detect TLS scrape errors in current logs.
is_docker_desktop=0
if kubectl get nodes -o name | grep -qi "docker-desktop"; then
  is_docker_desktop=1
fi

log "Check if metrics-server needs Docker Desktop TLS patch"
if [[ "${need_patch}" -eq 1 && "${is_docker_desktop}" -eq 1 ]]; then
  log "Patch metrics-server args for Docker Desktop (kubelet TLS verify issues)"
  # Add args (no duplicates with this JSON patch as long as you don't keep re-running after args already exist)
  kubectl -n kube-system patch deployment metrics-server --type='json' -p='[
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
    {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP"}
  ]' || true

  kubectl -n kube-system rollout restart deploy/metrics-server
  kubectl -n kube-system rollout status deploy/metrics-server --timeout=180s || true
else
  log "metrics-server patch skipped (already patched or not Docker Desktop)"
fi

# ------------------------------------------------------------------------------
# 4) Self-signed TLS secret for local Ingress
# ------------------------------------------------------------------------------
log "Create TLS secret (self-signed) in opsdesk"
tmpdir="$(mktemp -d)"
cleanup() { rm -rf "${tmpdir}"; }
trap cleanup EXIT

crt="${tmpdir}/opsdesk.crt"
key="${tmpdir}/opsdesk.key"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${key}" -out "${crt}" \
  -subj "/CN=opsdesk.local" \
  -addext "subjectAltName=DNS:opsdesk.local,DNS:api.opsdesk.local,DNS:grafana.opsdesk.local"

kubectl -n opsdesk create secret tls opsdesk-tls \
  --cert="${crt}" --key="${key}" \
  --dry-run=client -o yaml | kubectl apply -f -

# ------------------------------------------------------------------------------
# 5) Optional: observability stack (kube-prometheus-stack, loki, promtail)
# ------------------------------------------------------------------------------
if [[ "${INSTALL_OBSERVABILITY}" == "1" ]]; then
  log "Install observability stack (namespace: observability)"
  kubectl create ns observability --dry-run=client -o yaml | kubectl apply -f -

  log "Helm repos (prometheus-community, grafana)"
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo add grafana https://grafana.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo update >/dev/null

  if [[ -f "${ROOT_DIR}/${KPS_VALUES}" ]]; then
    log "Install/upgrade kube-prometheus-stack (kps)"
    helm upgrade --install kps prometheus-community/kube-prometheus-stack \
      -n observability \
      -f "${ROOT_DIR}/${KPS_VALUES}"
  else
    log "WARN: ${KPS_VALUES} not found, installing kube-prometheus-stack with defaults"
    helm upgrade --install kps prometheus-community/kube-prometheus-stack \
      -n observability
  fi

  if [[ -f "${ROOT_DIR}/${LOKI_VALUES}" ]]; then
    log "Install/upgrade loki"
    helm upgrade --install loki grafana/loki \
      -n observability \
      -f "${ROOT_DIR}/${LOKI_VALUES}"
  else
    log "WARN: ${LOKI_VALUES} not found, installing loki with defaults"
    helm upgrade --install loki grafana/loki \
      -n observability
  fi

  if [[ -f "${ROOT_DIR}/${PROMTAIL_VALUES}" ]]; then
    log "Install/upgrade promtail"
    helm upgrade --install promtail grafana/promtail \
      -n observability \
      -f "${ROOT_DIR}/${PROMTAIL_VALUES}"
  else
    log "WARN: ${PROMTAIL_VALUES} not found, installing promtail with defaults"
    helm upgrade --install promtail grafana/promtail \
      -n observability
  fi
else
  log "Observability install skipped (set INSTALL_OBSERVABILITY=1 to enable)"
fi

# ------------------------------------------------------------------------------
# Done
# ------------------------------------------------------------------------------
log "Bootstrap done "
log "Quick checks:"
log "  kubectl -n ${INGRESS_NGINX_NS} get pods"
log "  kubectl -n kube-system get pods | grep metrics"
log "  kubectl top nodes  (should work after metrics-server is healthy)"
log "  kubectl -n opsdesk get secrets | grep opsdesk-tls"
