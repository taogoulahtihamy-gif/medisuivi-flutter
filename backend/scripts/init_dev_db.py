"""Apply explicit, versioned migrations on an empty development database."""
from alembic import command
from alembic.config import Config
from app.main import settings

if __name__ == "__main__":
    if settings.environment != "development":
        raise SystemExit("Schema bootstrap only allowed in development")
    command.upgrade(Config("alembic.ini"), "head")
    print("Development schema migrated. Synthetic records ONLY.")
