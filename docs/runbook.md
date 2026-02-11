# OpsDesk Runbook (Jour 1)

## Prérequis
- Docker Desktop (Kubernetes activé)
- Git

## Démarrage toolbox
```powershell
docker compose -f .\docker-compose.toolbox.yml build
docker compose -f .\docker-compose.toolbox.yml run --rm toolbox bash
