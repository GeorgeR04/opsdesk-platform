SHELL := bash
.DEFAULT_GOAL := help

ENV ?= dev

.PHONY: help
help:
	@echo "OpsDesk targets:"
	@echo "  make bootstrap        -> install ingress-nginx + metrics-server + TLS secret"
	@echo "  INSTALL_OBSERVABILITY=1 make bootstrap -> make bootstrap +observa "
	@echo "  make ci ENV=dev       -> lint, test, build, scan, validate, deploy, smoke"
	@echo "  TRIVY_EXIT_CODE=0 make ci ENV=dev -> Scan but no fail" 
	@echo "  make cd               -> deploy overlay prod-like (local)"
	@echo "  make deploy ENV=dev   -> deploy overlay"
	@echo "  make rollback         -> kubectl rollout undo"
	@echo "  make smoke            -> curl health/ready + list pods"
	@echo "  make k9s              -> open k9s"
	@echo "  make clean            -> delete namespace opsdesk"

.PHONY: ci
ci: lint test build scan kustomize-validate deploy smoke

.PHONY: bootstrap
bootstrap:
	@./scripts/bootstrap.sh

.PHONY: lint
lint:
	@./scripts/lint.sh

.PHONY: test
test:
	@./scripts/test.sh

.PHONY: build
build:
	@./scripts/build.sh

.PHONY: scan
scan:
	@./scripts/scan.sh

.PHONY: kustomize-validate
kustomize-validate:
	@./scripts/deploy.sh --validate-only $(ENV)

.PHONY: deploy
deploy:
	@./scripts/deploy.sh $(ENV)

.PHONY: cd
cd:
	@ENV=prod-like $(MAKE) deploy smoke

.PHONY: rollback
rollback:
	@./scripts/rollback.sh

.PHONY: smoke
smoke:
	@./scripts/smoke.sh

.PHONY: k9s
k9s:
	k9s

.PHONY: clean
clean:
	kubectl delete ns opsdesk --ignore-not-found=true
