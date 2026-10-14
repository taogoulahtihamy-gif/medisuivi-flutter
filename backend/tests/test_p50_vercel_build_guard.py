"""Migration guard for Vercel. Does NOT connect to any real database."""
import pytest

from scripts import prepare_vercel_sandbox as deploy


@pytest.mark.parametrize("environment,database_url", [
    ("production", "postgresql+psycopg://demo:fake@x.neon.tech/medisuivi_sandbox?sslmode=require"),
    ("sandbox", "postgresql+psycopg://demo:fake@x.neon.tech/erp?sslmode=require"),
    ("sandbox", "postgresql+psycopg://demo:fake@localhost/medisuivi_sandbox?sslmode=require"),
    ("sandbox", "postgresql+psycopg://demo:fake@x.neon.tech/medisuivi_sandbox?sslmode=disable"),
    ("sandbox", "postgresql://demo:fake@x.neon.tech/medisuivi_sandbox?sslmode=require"),
    ("sandbox", ""),
])
def test_vercel_build_refuses_unsafe_database(monkeypatch, environment, database_url):
    monkeypatch.setenv("APP_ENV", environment)
    monkeypatch.setenv("APP_DATABASE_URL", database_url)
    monkeypatch.setattr(deploy.command, "upgrade",
                        lambda *_: pytest.fail("Unsafe migration executed"))
    with pytest.raises(SystemExit, match="Vercel build refused"):
        deploy.main()


def test_vercel_build_allows_only_neon_sandbox(monkeypatch):
    monkeypatch.setenv("APP_ENV", "sandbox")
    monkeypatch.setenv(
        "APP_DATABASE_URL",
        "postgresql+psycopg://demo:fake@ep-demo.eu-central-1.aws.neon.tech/"
        "medisuivi_sandbox?sslmode=require",
    )
    calls = []
    monkeypatch.setattr(deploy.command, "upgrade",
                        lambda config, revision: calls.append(revision))
    deploy.main()
    assert calls == ["head"]
