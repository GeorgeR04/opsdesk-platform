import os
from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool

from alembic import context
from app.models import Base  # noqa

config = context.config
fileConfig(config.config_file_name)


def get_url():
    return os.getenv("DATABASE_URL", "")


target_metadata = Base.metadata


def run_migrations_online():
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = get_url()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


run_migrations_online()
