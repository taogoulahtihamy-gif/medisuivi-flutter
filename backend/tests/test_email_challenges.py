"""Synthetic-only email confirmation and password recovery tests."""
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

import pytest
from sqlalchemy import select

from test_auth_isolation import client, fresh_database, register  # noqa: F401
from test_sessions_rotation import credentials, auth
from app.main import (
    EmailChallenge, SessionLocal, User, settings, hasher,
)


@pytest.fixture
def mailer(monkeypatch):
    sent = []
    monkeypatch.setattr(settings, "email_auth_enabled", True)
    monkeypatch.setenv("APP_SMTP_HOST", "mailpit")
    monkeypatch.setenv("APP_SMTP_FROM", "medisuivi-dev@localhost.invalid")
    with patch("app.main.send_security_code",
               side_effect=lambda email, purpose, code: sent.append(
                   (email, purpose, code))):
        yield sent


def posted(client, route, payload):
    return client.post("/api/v1/auth/" + route, json=payload)


def create_unverified(client, email="unverified@medisuvi-ci.org"):
    response = posted(client, "register", {
        "email": email, "password": "synthetic-safe-password-2026",
        "first_name": "Praticien", "last_name": "Fictif",
    })
    assert response.status_code == 201, response.text
    assert response.json()["email_verification_required"] is True
    return response.json()


def last_code(sent, purpose):
    return next(item[2] for item in reversed(sent) if item[1] == purpose)


def test_verification_required_and_session_blocked_until_code(client, mailer):
    email = "first@medisuvi-ci.org"
    created = create_unverified(client, email)
    assert mailer[0][:2] == (email, "verify_email")
    assert len(mailer[0][2]) == 12 and mailer[0][2].isdigit()
    with SessionLocal() as db:
        user = db.get(User, created["id"])
        assert user.email_verified is False
        row = db.scalar(select(EmailChallenge).where(
            EmailChallenge.user_id == user.id))
        assert row.code_digest != mailer[0][2]
        assert row.failed_attempts == 0

    blocked = posted(client, "login", {
        "email": email, "password": "synthetic-safe-password-2026",
    })
    assert blocked.status_code == 403
    assert blocked.json()["detail"] == "Adresse e-mail non vérifiée"

    verified = posted(client, "email/verify",
                      {"email": email, "code": last_code(mailer, "verify_email")})
    assert verified.status_code == 204, verified.text
    assert posted(client, "email/verify", {
        "email": email, "code": last_code(mailer, "verify_email")
    }).status_code == 400
    assert posted(client, "login", {
        "email": email, "password": "synthetic-safe-password-2026",
    }).status_code == 200


def test_verification_wrong_guess_limit_expiry_and_resend(client, mailer):
    email = "guess@medisuvi-ci.org"
    user = create_unverified(client, email)
    first_code = last_code(mailer, "verify_email")
    for i in range(5):
        response = posted(client, "email/verify", {
            "email": email, "code": "000000000000",
        })
        assert response.status_code == 400
    assert posted(client, "email/verify", {
        "email": email, "code": first_code,
    }).status_code == 400
    with SessionLocal() as db:
        row = db.scalar(select(EmailChallenge).where(
            EmailChallenge.user_id == user["id"]))
        assert row.failed_attempts == 5
        row.created_at = datetime.now(timezone.utc) - timedelta(minutes=2)
        db.commit()
    resent = posted(client, "email/resend", {"email": email})
    assert resent.status_code == 202
    second = last_code(mailer, "verify_email")
    assert second != first_code
    assert posted(client, "email/verify", {
        "email": email, "code": first_code,
    }).status_code == 400

    with SessionLocal() as db:
        row = db.scalar(select(EmailChallenge).where(
            EmailChallenge.user_id == user["id"],
            EmailChallenge.consumed_at.is_(None)))
        row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
        db.commit()
    assert posted(client, "email/verify", {
        "email": email, "code": second,
    }).status_code == 400


def test_resend_cooldown_and_unknown_are_generic(client, mailer):
    email = "resend@medisuvi-ci.org"
    create_unverified(client, email)
    count = len(mailer)
    known = posted(client, "email/resend", {"email": email})
    missing = posted(client, "email/resend",
                     {"email": "missing@medisuvi-ci.org"})
    assert known.status_code == missing.status_code == 202
    assert known.json() == missing.json()
    assert len(mailer) == count, "one minute resend cooldown"


def test_reset_password_revokes_all_devices_and_rejects_reuse(client, mailer):
    email = "reset@medisuvi-ci.org"
    register(client, email)  # email flag true here: verifies first
    assert posted(client, "email/verify", {
        "email": email, "code": last_code(mailer, "verify_email")
    }).status_code == 204
    device_a = credentials(client, email, password="not-a-real-password-2026")
    device_b = credentials(client, email, password="not-a-real-password-2026")

    known = posted(client, "password/forgot", {"email": email})
    missing = posted(client, "password/forgot",
                     {"email": "nobody@medisuvi-ci.org"})
    assert known.status_code == missing.status_code == 202
    assert known.json() == missing.json()
    reset_code = last_code(mailer, "reset_password")

    response = posted(client, "password/reset", {
        "email": email, "code": reset_code,
        "new_password": "new-synthetic-password-2026",
    })
    assert response.status_code == 204, response.text
    assert posted(client, "password/reset", {
        "email": email, "code": reset_code,
        "new_password": "another-synthetic-password-2026",
    }).status_code == 400

    for device in (device_a, device_b):
        assert client.get("/api/v1/me", headers=auth(device)).status_code == 401
        assert posted(client, "refresh", {
            "refresh_token": device["refresh_token"],
        }).status_code == 401
    assert posted(client, "login", {
        "email": email, "password": "not-a-real-password-2026",
    }).status_code == 401
    assert posted(client, "login", {
        "email": email, "password": "new-synthetic-password-2026",
    }).status_code == 200


def test_password_reset_wrong_guesses_and_expired_code(client, mailer):
    email = "expiry@medisuvi-ci.org"
    user = create_unverified(client, email)
    assert posted(client, "email/verify", {
        "email": email, "code": last_code(mailer, "verify_email")
    }).status_code == 204
    assert posted(client, "password/forgot", {"email": email}).status_code == 202
    code = last_code(mailer, "reset_password")
    for _ in range(5):
        assert posted(client, "password/reset", {
            "email": email, "code": "000000000000",
            "new_password": "synthetic-alternate-password",
        }).status_code == 400
    assert posted(client, "password/reset", {
        "email": email, "code": code,
        "new_password": "synthetic-alternate-password",
    }).status_code == 400
    with SessionLocal() as db:
        challenge = db.scalar(select(EmailChallenge).where(
            EmailChallenge.user_id == user["id"],
            EmailChallenge.purpose == "reset_password"))
        challenge.created_at = datetime.now(timezone.utc) - timedelta(minutes=2)
        db.commit()
    assert posted(client, "password/forgot", {"email": email}).status_code == 202
    newer = last_code(mailer, "reset_password")
    with SessionLocal() as db:
        row = db.scalar(select(EmailChallenge).where(
            EmailChallenge.user_id == user["id"],
            EmailChallenge.purpose == "reset_password",
            EmailChallenge.consumed_at.is_(None)))
        row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=3)
        db.commit()
    assert posted(client, "password/reset", {
        "email": email, "code": newer, "new_password": "synthetic-new-2026-password",
    }).status_code == 400


def test_mail_failure_rolls_back_registration_and_challenge(client, mailer):
    with patch("app.main.send_security_code",
               side_effect=RuntimeError("smtp timeout, no credentials in response")):
        response = posted(client, "register", {
            "email": "failure@medisuvi-ci.org",
            "password": "synthetic-safe-password-2026",
            "first_name": "Test", "last_name": "Fictif",
        })
    assert response.status_code == 503
    assert "timeout" not in response.text
    with SessionLocal() as db:
        assert db.scalar(select(User).where(
            User.email == "failure@medisuvi-ci.org")) is None


def test_disabled_mail_feature_does_not_change_legacy_login(client, monkeypatch):
    monkeypatch.setattr(settings, "email_auth_enabled", False)
    register(client, "legacy@medisuvi-ci.org")
    assert posted(client, "password/forgot", {
        "email": "legacy@medisuvi-ci.org"
    }).status_code == 403
    assert posted(client, "login", {
        "email": "legacy@medisuvi-ci.org",
        "password": "not-a-real-password-2026",
    }).status_code == 200
