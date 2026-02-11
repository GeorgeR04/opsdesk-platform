import os

from celery import Celery

BROKER = os.getenv("CELERY_BROKER_URL", os.getenv("REDIS_URL", "redis://redis:6379/0"))
BACKEND = os.getenv("CELERY_RESULT_BACKEND", BROKER)

celery_app = Celery("opsdesk", broker=BROKER, backend=BACKEND)
