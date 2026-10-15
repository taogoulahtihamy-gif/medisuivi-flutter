"""Public signup staging regression tests; synthetic identities only."""
import pytest
from fastapi.testclient import TestClient

from app.main import Base, SessionLocal, User, app, engine, settings
from sqlalchemy import select


@pytest.fixture
def staging_signup(monkeypatch):
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    monkeypatch.setattr(settings, "environment", "staging")
    monkeypatch.setattr(settings, "public_registration_enabled", True)
    monkeypatch.setattr(settings, "email_auth_enabled", True)
    monkeypatch.setattr("app.main._email_flow_enabled", lambda: None)
    sent = []
    monkeypatch.setattr("app.main.send_security_code",
                        lambda email, purpose, code: sent.append((email, purpose, code)))
    yield sent
    Base.metadata.drop_all(engine)


def test_public_signup_requires_verification(staging_signup):
    with TestClient(app) as client:
        email = "staging-registration@example.com"
        payload = dict(first_name="Test", last_name="Praticien",
                       email=email, password="Synthetic-password-2026!")
        result = client.post("/api/v1/auth/register", json=payload)
        assert result.status_code == 201, result.text
        assert result.json()["email_verification_required"] is True
        assert len(staging_signup) == 1
        login = client.post("/api/v1/auth/login",
                            json={"email": email, "password": payload["password"]})
        assert login.status_code != 200
        code = staging_signup[0][2]
        assert client.post("/api/v1/auth/email/verify",
                           json={"email": email, "code": code}).status_code == 204
        assert client.post("/api/v1/auth/login",
                           json={"email": email, "password": payload["password"]}).status_code == 200


def test_public_signup_is_closed_without_feature_flag(staging_signup, monkeypatch):
    monkeypatch.setattr(settings, "public_registration_enabled", False)
    with TestClient(app) as client:
        response = client.post("/api/v1/auth/register", json={
            "first_name": "Test", "last_name": "Praticien",
            "email": "flag-closed@example.com",
            "password": "Synthetic-password-2026!",
        })
        assert response.status_code == 403


def test_staging_signup_does_not_require_invite_or_demo_email(staging_signup):
    with TestClient(app) as client:
        response = client.post("/api/v1/auth/register", json={
            "first_name": "Test", "last_name": "Praticien",
            "email": "normal.address@gmail.com",
            "password": "Synthetic-password-2026!",
        })
        assert response.status_code == 201, response.text
        with SessionLocal() as db:
            user = db.scalar(select(User).where(User.email == "normal.address@gmail.com"))
            assert user is not None
            assert not user.email_verified
