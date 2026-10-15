"""Migrate only the dedicated Neon sandbox during a Vercel build.

No printed credentials, no local/ERP/production database.
The operation runs before the FastAPI function is published.
"""
import os
from urllib.parse import parse_qs, urlsplit

from alembic import command
from alembic.config import Config


def main() -> None:
    if os.environ.get("APP_ENV") != "sandbox":
        raise SystemExit("Vercel build refused: APP_ENV must be sandbox")
    url = os.environ.get("APP_DATABASE_URL", "")
    parsed = urlsplit(url)
    query = parse_qs(parsed.query)
    if not (
        parsed.scheme == "postgresql+psycopg"
        and parsed.hostname
        and parsed.hostname.endswith(".neon.tech")
        and parsed.path == "/medisuivi_sandbox"
        and query.get("sslmode", [""])[0] in
        {"require", "verify-ca", "verify-full"}
    ):
        raise SystemExit(
            "Vercel build refused: only medisuivi_sandbox on TLS Neon is allowed"
        )
    # Migration is idempotent. No database credentials or SQL are printed.
    command.upgrade(Config("alembic.ini"), "head")
    print("Dedicated Neon sandbox schema validated and migrated")


if __name__ == "__main__":
    main()
