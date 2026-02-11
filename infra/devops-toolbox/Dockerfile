FROM python:3.12-slim-bookworm

ARG DEBIAN_FRONTEND=noninteractive

# Pins
ARG HELM_VERSION="v3.14.4"
ARG KUSTOMIZE_VERSION="v5.4.3"

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates curl git bash jq openssl \
  unzip gnupg coreutils wget vim less netcat-traditional \
  make file \
  tini \
  && rm -rf /var/lib/apt/lists/*

# Docker CLI + docker compose plugin (client only, no daemon)
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
    > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

# yq
RUN curl -fsSL -o /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  && chmod +x /usr/local/bin/yq \
  && yq --version

# kubectl (latest stable at build time)
RUN curl -fsSL -o /usr/local/bin/kubectl \
  "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x /usr/local/bin/kubectl \
  && kubectl version --client=true --output=yaml

# helm
RUN curl -fsSL -o /tmp/helm.tgz \
  "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
  && tar -xzf /tmp/helm.tgz -C /tmp \
  && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm \
  && rm -rf /tmp/* \
  && helm version

# kustomize (pinned)
RUN curl -fsSL -o /tmp/kustomize.tgz \
  "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
  && tar -xzf /tmp/kustomize.tgz -C /usr/local/bin \
  && chmod +x /usr/local/bin/kustomize \
  && rm -f /tmp/kustomize.tgz \
  && kustomize version

# k9s (latest)
RUN curl -fsSL -o /tmp/k9s.tgz \
  https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz \
  && tar -xzf /tmp/k9s.tgz -C /usr/local/bin k9s \
  && chmod +x /usr/local/bin/k9s \
  && rm -rf /tmp/* \
  && k9s version

# trivy
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
  > /etc/apt/sources.list.d/trivy.list \
  && apt-get update && apt-get install -y --no-install-recommends trivy \
  && rm -rf /var/lib/apt/lists/* \
  && trivy --version

# ✅ Create venv as root (so /opt is writable), install deps
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install -U "pip<26" wheel


# ✅ Create user AFTER, then give ownership
RUN useradd -ms /bin/bash dev \
  && mkdir -p /workspace /home/dev/.kube \
  && chown -R dev:dev /workspace /opt/venv /home/dev

WORKDIR /workspace

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PATH="/opt/venv/bin:${PATH}"

# ✅ Entry script: show versions once, then exec command
RUN printf '%s\n' \
  '#!/usr/bin/env bash' \
  'set -euo pipefail' \
  'echo "==> toolbox versions"' \
  'python3 --version || true' \
  'pip --version || true' \
  'kubectl version --client=true --short 2>/dev/null || true' \
  'helm version --short 2>/dev/null || true' \
  'kustomize version 2>/dev/null || true' \
  'yq --version 2>/dev/null || true' \
  'trivy --version 2>/dev/null || true' \
  'k9s version 2>/dev/null || true' \
  'echo "==> running: $*"' \
  'exec "$@"' \
  > /usr/local/bin/entrypoint.sh \
  && chmod +x /usr/local/bin/entrypoint.sh

USER dev

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
