import logging
import os
import time
import uuid

from fastapi import FastAPI, Request
from prometheus_client import make_asgi_app

from app.logging import ContextFilter, request_id_ctx, setup_logging
from app.metrics import HTTP_LATENCY, HTTP_REQUESTS
from app.routes.changes import router as changes_router
from app.routes.health import router as health_router
from app.routes.stats import router as stats_router

setup_logging()
logging.getLogger().addFilter(ContextFilter())
log = logging.getLogger("opsdesk.api")

app = FastAPI(title="OpsDesk API", version=os.getenv("VERSION", "dev"))

# Prometheus metrics endpoint
app.mount("/metrics", make_asgi_app())


@app.middleware("http")
async def observability_mw(request: Request, call_next):
    rid = request.headers.get("x-request-id") or str(uuid.uuid4())
    token = request_id_ctx.set(rid)

    start = time.perf_counter()
    status = "500"
    path = request.url.path

    try:
        response = await call_next(request)
        status = str(response.status_code)

        # Route pattern (faible cardinalité) si dispo
        route = request.scope.get("route")
        if route and getattr(route, "path", None):
            path = route.path

        return response
    finally:
        elapsed = time.perf_counter() - start
        HTTP_REQUESTS.labels(request.method, path, status).inc()
        HTTP_LATENCY.labels(request.method, path).observe(elapsed)
        request_id_ctx.reset(token)


# Routers
app.include_router(health_router)
app.include_router(changes_router, prefix="/api")
app.include_router(stats_router, prefix="/api")


@app.get("/api/ping")
def ping():
    log.info("ping", extra={"request_id": "-"})
    return {"ok": True}
