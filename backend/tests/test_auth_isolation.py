"""Synthetic-only API security tests. No real patient information."""
import os
import tempfile
from pathlib import Path

import pytest

# Must be configured before importing app.main; it fails closed otherwise.
_TEMP_DIR = tempfile.TemporaryDirectory(prefix="medisuivi-test-")
os.environ["APP_ENV"] = "test"
os.environ["APP_DATABASE_URL"] = (
    "sqlite+pysqlite:///" + str(Path(_TEMP_DIR.name) / "isolated.db")
)
os.environ["APP_JWT_SECRET"] = "test-only-deterministic-not-for-production-" * 2
os.environ["APP_ALLOW_DEVELOPMENT_REGISTRATION"] = "false"

from fastapi.testclient import TestClient  # noqa: E402
from app.main import Base, Patient, SessionLocal, Settings, User, app, engine, hasher, settings  # noqa: E402


@pytest.fixture(autouse=True)
def fresh_database(monkeypatch):
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    monkeypatch.setattr(settings, "environment", "development")
    monkeypatch.setattr(settings, "allow_registration", True)
    yield
    Base.metadata.drop_all(engine)


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def register(client, email, password="not-a-real-password-2026"):
    response = client.post("/api/v1/auth/register", json={
        "email": email, "password": password, "first_name": "Médecin",
        "last_name": "Test",
    })
    assert response.status_code == 201, response.text
    return response.json()


def login(client, email, password="not-a-real-password-2026"):
    result = client.post("/api/v1/auth/login", json={
        "email": email, "password": password,
    })
    assert result.status_code == 200, result.text
    return {"Authorization": "Bearer " + result.json()["access_token"]}


def test_health_and_ready(client):
    assert client.get("/health").json()["status"] == "ok"
    assert client.get("/ready").json()["ready"] is True


def test_signup_and_hash_are_not_plaintext(client):
    practitioner = register(client, "praticien@medisuvi-ci.org")
    with SessionLocal() as db:
        row = db.get(User, practitioner["id"])
        assert row is not None
        assert row.password_hash != "not-a-real-password-2026"
        assert row.password_hash.startswith("$argon2id$")
        assert hasher.verify(row.password_hash, "not-a-real-password-2026")
    headers = login(client, "praticien@medisuvi-ci.org")
    response = client.get("/api/v1/me", headers=headers)
    assert response.status_code == 200
    assert response.json()["email"] == "praticien@medisuvi-ci.org"
    assert "password_hash" not in response.json()


def test_registration_is_explicitly_disabled_by_default(client, monkeypatch):
    monkeypatch.setattr(settings, "allow_registration", False)
    assert client.post("/api/v1/auth/register", json={
        "email": "blocked@medisuvi-ci.org", "password": "long-good-password",
        "first_name": "Non", "last_name": "Permis",
    }).status_code == 403


def test_authentication_rejects_bad_password_and_missing_token(client):
    register(client, "medecin@medisuvi-ci.org")
    assert client.post("/api/v1/auth/login", json={
        "email": "medecin@medisuvi-ci.org", "password": "wrong",
    }).status_code == 401
    assert client.get("/api/v1/me").status_code == 401
    assert client.get("/api/v1/patients").status_code == 401


def test_two_accounts_have_strictly_isolated_patients(client):
    register(client, "alpha@medisuvi-ci.org")
    register(client, "beta@medisuvi-ci.org")
    a = login(client, "alpha@medisuvi-ci.org")
    b = login(client, "beta@medisuvi-ci.org")
    created = client.post("/api/v1/patients", headers=a, json={
        "display_name": "PATIENT FICTIF A", "age": 30,
    })
    assert created.status_code == 201
    patient_id = created.json()["id"]
    assert "owner_user_id" not in created.json()

    assert len(client.get("/api/v1/patients", headers=a).json()) == 1
    assert client.get("/api/v1/patients", headers=b).json() == []
    assert client.get(f"/api/v1/patients/{patient_id}", headers=b).status_code == 404
    assert client.get(f"/api/v1/patients/{patient_id}", headers=a).status_code == 200
    assert client.get("/api/v1/patients/not-found", headers=a).status_code == 404
    assert client.post("/api/v1/patients", headers=b, json={
        "display_name": "INJECTION", "age": 28,
        "owner_user_id": created.json()["id"],
    }).status_code == 422


def test_logout_revokes_previous_access_tokens(client):
    register(client, "logout@medisuvi-ci.org")
    token = login(client, "logout@medisuvi-ci.org")
    assert client.get("/api/v1/me", headers=token).status_code == 200
    assert client.post("/api/v1/auth/logout", headers=token).status_code == 204
    assert client.get("/api/v1/me", headers=token).status_code == 401
    assert client.get("/api/v1/me", headers=login(client, "logout@medisuvi-ci.org")).status_code == 200


def test_staging_rejects_registration_and_patient_writes(client, monkeypatch):
    register(client, "staging@medisuvi-ci.org")
    token = login(client, "staging@medisuvi-ci.org")
    monkeypatch.setattr(settings, "environment", "staging")
    assert client.post("/api/v1/auth/register", json={
        "email": "extra@medisuvi-ci.org", "password": "long-good-password",
        "first_name": "No", "last_name": "No",
    }).status_code == 403
    assert client.post("/api/v1/patients", headers=token, json={
        "display_name": "No", "age": 25,
    }).status_code == 403


def test_production_configuration_fails_closed(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    with pytest.raises(RuntimeError, match="production prohibited"):
        Settings()


def test_staging_opt_in_accepts_only_synthetic_patients(client, monkeypatch):
    register(client, "staging-synthetic@medisuvi-ci.org")
    token = login(client, "staging-synthetic@medisuvi-ci.org")
    monkeypatch.setattr(settings, "environment", "staging")
    monkeypatch.setattr(settings, "staging_synthetic_writes_enabled", True)
    assert client.post("/api/v1/patients", headers=token, json={
        "display_name": "Personne réelle", "age": 30,
    }).status_code == 422
    response = client.post("/api/v1/patients", headers=token, json={
        "display_name": "PATIENT FICTIF DEMO", "age": 30,
    })
    assert response.status_code == 201, response.text
    rows = client.get("/api/v1/patients", headers=token)
    assert rows.status_code == 200
    assert any(x["display_name"] == "PATIENT FICTIF DEMO" for x in rows.json())
