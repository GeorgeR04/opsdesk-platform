from prometheus_client import Counter, Histogram

# Garder path faible cardinalité → on utilisera le "route pattern" (ex: /api/changes)
HTTP_REQUESTS = Counter(
    "opsdesk_http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)

HTTP_LATENCY = Histogram(
    "opsdesk_http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "path"],
    buckets=(0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5),
)
