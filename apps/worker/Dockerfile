FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

ARG UID=10001
ARG GID=10001

RUN set -eux; \
    addgroup --gid "${GID}" appgroup; \
    adduser  --uid "${UID}" --ingroup appgroup --disabled-password --gecos "" appuser; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -U pip && pip install --no-cache-dir -r requirements.txt

# Code worker
COPY worker ./worker

RUN chown -R "${UID}:${GID}" /app
USER ${UID}:${GID}

# Defaults sûrs pour petit cluster / dev
ENV CELERY_LOGLEVEL=info \
    CELERY_POOL=solo \
    CELERY_CONCURRENCY=1

CMD ["sh","-c", "celery -A worker.tasks:celery_app worker -l ${CELERY_LOGLEVEL} --pool=${CELERY_POOL} --concurrency=${CELERY_CONCURRENCY} --without-gossip --without-mingle --without-heartbeat"]
