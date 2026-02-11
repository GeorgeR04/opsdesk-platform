# OpsDesk — DevOps/SRE Kubernetes Portfolio

OpsDesk is a **local-first DevOps/SRE portfolio project** running on **Kubernetes (Docker Desktop)**.  
It demonstrates a production-like workflow with **Kustomize overlays**, a **Makefile-driven CI/CD pipeline**, and optional **observability** (Grafana / Loki / Prometheus) — all executed from a dedicated **devops-toolbox** container.

---

## ✨ What this project showcases

- **Kubernetes-first architecture** (Ingress, services, deployments/statefulsets)
- **Kustomize**: `base/` + overlays (`dev`, `prod-like`)
- **Local CI/CD** via Make targets:
  - lint → test → build → scan → deploy → smoke
- **Security-minded manifests**:
  - non-root containers, drop Linux caps, seccomp, resource limits
- **Observability-ready** stack (optional):
  - metrics → Prometheus → Grafana
  - logs → Promtail → Loki → Grafana Explore

---

## 🧱 Components

- **Frontend**: React + Vite (served by Nginx)
- **API**: FastAPI  
  - `/health`, `/ready`, `/metrics`  
  - minimal CRUD under `/api/changes`
- **Worker**: background worker (Redis broker) + Postgres persistence
- **Postgres**: Stateful storage for API/worker
- **Redis**: broker/cache for async jobs

---

## 🌐 Local Domains

Add these entries to your Windows hosts file (**run as Administrator**):

**File:** `C:\Windows\System32\drivers\etc\hosts`

```txt
127.0.0.1 opsdesk.local
127.0.0.1 api.opsdesk.local
127.0.0.1 grafana.opsdesk.local
```

> TLS is self-signed for local usage, so your browser may show a warning (e.g., `ERR_CERT_AUTHORITY_INVALID`).

---

## 🗂️ Repository layout

```txt
apps/        # frontend, api, worker
infra/       # dockerfiles, toolbox, CI configs
k8s/         # base + overlays (dev, prod-like)
scripts/     # Makefile helper scripts (bootstrap/build/deploy/smoke...)
docs/        # optional documentation
```

---

## ✅ Prerequisites

- Docker Desktop (Windows)
- Kubernetes enabled in Docker Desktop
- (Recommended) Git Bash or PowerShell
- Your kubeconfig available at: `%USERPROFILE%\.kube\config`

---

## 🚀 Quickstart (recommended: devops-toolbox)

This project is designed to be run through the **devops-toolbox** container (includes kubectl/helm/kustomize/trivy/etc.).

### 1) Build the toolbox

```powershell
docker compose -f .\docker-compose.toolbox.yml build toolbox
```

### 2) Bootstrap the cluster

Installs/ensures common prerequisites (Ingress, metrics-server, TLS secret, etc.).

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox make bootstrap
```

### 3) Run local CI (dev overlay)

Runs lint/test/build/scan + deploys the `dev` overlay + smoke checks.

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox make ci ENV=dev
```

### 4) Deploy “prod-like” overlay

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox make cd
```

---

## 🔎 Smoke checks (expected)

### API readiness

```bash
curl -sk https://api.opsdesk.local/ready
```

Expected:

```json
{"ready":true}
```

### API health

```bash
curl -sk https://api.opsdesk.local/health
```

Expected:

```json
{"status":"ok"}
```

### Minimal CRUD — “Change”

Create:

```bash
curl -sk -X POST https://api.opsdesk.local/api/changes \
  -H "Content-Type: application/json" \
  -d '{"id":"chg-001","title":"Enable feature flag X","status":"OPEN","created_at":0}'
```

List:

```bash
curl -sk https://api.opsdesk.local/api/changes
```

Expected:
- the list contains `chg-001`
- server sets `created_at` as a real timestamp

---

## 🧰 Useful commands

### View pods

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk get pods
```

### View ingress

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk get ingress
```

### Rollout status

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk rollout status deploy/opsdesk-api
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk rollout status deploy/opsdesk-frontend
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk rollout status deploy/opsdesk-worker
```

### Logs (API)

```powershell
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox kubectl -n opsdesk logs deploy/opsdesk-api --tail=200
```

---

## 🔐 Security notes

This repo aims to follow Kubernetes hardening best practices:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ["ALL"]`
- `seccompProfile: RuntimeDefault`
- CPU/RAM requests & limits

---

## 📌 Notes / Troubleshooting

### Browser TLS warning on Grafana

If you see `ERR_CERT_AUTHORITY_INVALID` on `grafana.opsdesk.local`, it is expected with self-signed TLS.

**Fix (optional):**
- Use `mkcert` to generate a locally trusted certificate
- Update the Kubernetes TLS secret referenced by the Grafana Ingress

### Windows line endings (CRLF)

To avoid breaking Linux scripts in Docker/K8s, force LF using `.gitattributes`:
- keep `.sh`, `.yaml`, Dockerfiles as `LF`


