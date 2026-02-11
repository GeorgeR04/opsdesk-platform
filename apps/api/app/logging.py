import contextvars
import logging
import os

from pythonjsonlogger import jsonlogger

request_id_ctx = contextvars.ContextVar("request_id", default="-")


def setup_logging() -> None:
    level = os.getenv("LOG_LEVEL", "INFO").upper()
    logger = logging.getLogger()
    logger.setLevel(level)

    handler = logging.StreamHandler()
    formatter = jsonlogger.JsonFormatter(
        "%(asctime)s %(levelname)s %(name)s %(message)s "
        "%(service)s %(env)s %(version)s %(request_id)s"
    )
    handler.setFormatter(formatter)
    logger.handlers = [handler]


class ContextFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.service = os.getenv("SERVICE_NAME", "api")
        record.env = os.getenv("ENV", "dev")
        record.version = os.getenv("VERSION", "dev")
        record.request_id = request_id_ctx.get()
        return True
