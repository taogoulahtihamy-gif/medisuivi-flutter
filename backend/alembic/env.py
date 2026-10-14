"""MediSuivi migrations. Secrets stay in APP_DATABASE_URL, not in git."""
from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool
from app.main import Base, settings

config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata
config.set_main_option("sqlalchemy.url", settings.database_url.replace("%", "%%"))


def migrations_offline() -> None:
    context.configure(
        url=settings.database_url,
        target_metadata=target_metadata, literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.", poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata,
            compare_type=True, transactional_ddl=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    migrations_offline()
else:
    migrations_online()
