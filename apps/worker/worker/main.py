#!/usr/bin/env python3
import os
import shlex
import sys


def _env_int(name: str, default: int) -> int:
    v = os.getenv(name)
    if not v:
        return default
    try:
        return int(v)
    except ValueError:
        print(f"[worker] Invalid {name}={v!r}, using {default}", file=sys.stderr)
        return default


def main() -> None:
    loglevel = os.getenv("CELERY_LOGLEVEL", "INFO")
    concurrency = _env_int("CELERY_CONCURRENCY", 1)   
    pool = os.getenv("CELERY_POOL", "solo")           
    queues = os.getenv("CELERY_QUEUES", "celery")

    # Optional extra args (debug, etc.)
    extra = os.getenv("CELERY_EXTRA_ARGS", "").strip()

    cmd = [
        "celery",
        "-A",
        "worker.tasks:celery_app",
        "worker",
        f"--loglevel={loglevel}",
        f"--concurrency={concurrency}",
        f"--pool={pool}",
        f"--queues={queues}",
        "--without-gossip",
        "--without-mingle",
        "--without-heartbeat",
    ]

    if extra:
        cmd += shlex.split(extra)

    os.execvp(cmd[0], cmd)


if __name__ == "__main__":
    main()
