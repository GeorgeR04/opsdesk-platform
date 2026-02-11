import logging
import os
from pythonjsonlogger import jsonlogger

def setup_logging() -> None:
    level = os.getenv("LOG_LEVEL", "INFO").upper()
    root = logging.getLogger()
    root.setLevel(level)

    h = logging.StreamHandler()
    fmt = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s %(service)s %(env)s %(version)s"
    )
    h.setFormatter(fmt)
    root.handlers = [h]

class ContextFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.service = os.getenv("SERVICE_NAME", "worker")
        record.env = os.getenv("ENV", "dev")
        record.version = os.getenv("VERSION", "dev")
        return True
