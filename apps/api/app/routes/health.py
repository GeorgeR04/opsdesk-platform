import os

import redis as redis_lib
from fastapi import APIRouter

from app.db import db_ok

router = APIRouter()


@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/ready")
def ready():
    redis_url = os.getenv("REDIS_URL", "")
    r_ok = False
    try:
        r = redis_lib.Redis.from_url(redis_url, socket_connect_timeout=1)
        r_ok = r.ping() is True
    except Exception:
        r_ok = False

    return {"ready": bool(db_ok() and r_ok)}
