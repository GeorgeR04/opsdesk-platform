import os

def pytest_configure():
    os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///./opsdesk_test.db")
