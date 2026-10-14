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
    practitioner = register(client, "praticien@example.test")
    with SessionLocal() as db:
        row = db.get(User, practitioner["id"])
        assert row is not None
        assert row.password_hash != "not-a-real-password-2026"
        assert row.password_hash.startswith("$argon2id$")
        assert hasher.verify(row.password_hash, "not-a-real-password-2026")
    headers = login(client, "praticien@example.test")
    response = client.get("/api/v1/me", headers=headers)
    assert response.status_code == 200
    assert response.json()["email"] == "praticien@example.test"
    assert "password_hash" not in response.json()


def test_registration_is_explicitly_disabled_by_default(client, monkeypatch):
    monkeypatch.setattr(settings, "allow_registration", False)
    assert client.post("/api/v1/auth/register", json={
        "email": "blocked@example.test", "password": "long-good-password",
        "first_name": "Non", "last_name": "Permis",
    }).status_code == 403


def test_authentication_rejects_bad_password_and_missing_token(client):
    register(client, "medecin@example.test")
    assert client.post("/api/v1/auth/login", json={
        "email": "medecin@example.test", "password": "wrong",
    }).status_code == 401
    assert client.get("/api/v1/me").status_code == 401
    assert client.get("/api/v1/patients").status_code == 401


def test_two_accounts_have_strictly_isolated_patients(client):
    register(client, "alpha@example.test")
    register(client, "beta@example.test")
    a = login(client, "alpha@example.test")
    b = login(client, "beta@example.test")
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
    register(client, "logout@example.test")
    token = login(client, "logout@example.test")
    assert client.get("/api/v1/me", headers=token).status_code == 200
    assert client.post("/api/v1/auth/logout", headers=token).status_code == 204
    assert client.get("/api/v1/me", headers=token).status_code == 401
    assert client.get("/api/v1/me", headers=login(client, "logout@example.test")).status_code == 200


def test_staging_rejects_registration_and_patient_writes(client, monkeypatch):
    register(client, "staging@example.test")
    token = login(client, "staging@example.test")
    monkeypatch.setattr(settings, "environment", "staging")
    assert client.post("/api/v1/auth/register", json={
        "email": "extra@example.test", "password": "long-good-password",
        "first_name": "No", "last_name": "No",
    }).status_code == 403
    assert client.post("/api/v1/patients", headers=token, json={
        "display_name": "No", "age": 25,
    }).status_code == 403


def test_production_configuration_fails_closed(monkeypatch):
    monkeypatch.setenv("APP_ENV", "production")
    with pytest.raises(RuntimeError, match="production prohibited"):
        Settings()
