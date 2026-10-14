"""P4.7: verify that publicly reachable staging cannot create clinical records.

Run ONLY with the disposable PostgreSQL database named medisuivi_ci.
This test creates exactly one synthetic credential in isolated CI.
"""
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import (
    SessionLocal, User, app, engine, hasher, settings,
)


def test_staging_refuses_registration_and_patient_writes():
    assert engine.dialect.name == "postgresql"
    assert engine.url.database == "medisuivi_ci", (
        "Never run this CI test against a real or local clinical database"
    )
    assert settings.environment == "staging"
    assert settings.allow_registration is False
    assert settings.email_auth_enabled is False
    with engine.connect() as db:
        assert db.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0005"

    address = f"p47-synthetic-{uuid4().hex}@medisuvi-ci.org"
    password = "P47-only-synthetic-secret-with-no-real-user"
    with SessionLocal() as db:
        user = User(
            email=address,
            password_hash=hasher.hash(password),
            first_name="Compte",
            last_name="Fictif",
            email_verified=True,
        )
        db.add(user)
        db.commit()

    with TestClient(app) as client:
        assert client.get("/health").status_code == 200
        assert client.get("/ready").status_code == 200

        forbidden_register = client.post("/api/v1/auth/register", json={
            "email": f"extra-{uuid4().hex}@medisuvi-ci.org",
            "password": "P47-extra-synthetic-password",
            "first_name": "Compte", "last_name": "Fictif",
        })
        assert forbidden_register.status_code == 403

        login = client.post("/api/v1/auth/login", json={
            "email": address,
            "password": password,
        })
        assert login.status_code == 200, login.text
        token = {"Authorization": f"Bearer {login.json()['access_token']}"}

        patient_list = client.get("/api/v1/patients", headers=token)
        assert patient_list.status_code == 200
        assert patient_list.json() == []
        forbidden_create = client.post("/api/v1/patients", headers=token, json={
            "display_name": "PATIENT FICTIF INTERDIT",
            "age": 26,
        })
        assert forbidden_create.status_code == 403
        assert client.get("/api/v1/patients", headers=token).json() == []

        assert client.post("/api/v1/auth/logout", headers=token).status_code == 204
        assert client.get("/api/v1/patients", headers=token).status_code == 401
