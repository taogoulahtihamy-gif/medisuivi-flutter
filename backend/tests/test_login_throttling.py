"""Synthetic authentication abuse tests: no real user or patient credentials."""
from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from test_auth_isolation import client, fresh_database, register  # noqa: F401
from app.main import (LOGIN_FAILURE_LIMIT, LoginAttempt, SessionLocal,
                      _login_key, settings)


def attempt(client, email, password):
    return client.post("/api/v1/auth/login", json={
        "email": email, "password": password,
    })


def test_lockout_for_known_and_unknown_email_is_indistinguishable(client):
    account = "practitioner@medisuvi-ci.org"
    missing = "unknown@medisuvi-ci.org"
    register(client, account)
    for n in range(LOGIN_FAILURE_LIMIT):
        known = attempt(client, account, "invalid-password")
        unknown = attempt(client, missing, "invalid-password")
        expect = 429 if n == LOGIN_FAILURE_LIMIT - 1 else 401
        assert known.status_code == unknown.status_code == expect
        assert known.json() == unknown.json()
        if expect == 429:
            assert int(known.headers["Retry-After"]) > 0
            assert int(unknown.headers["Retry-After"]) > 0

    # Even the correct password remains blocked until the lock expires.
    blocked = attempt(client, account, "not-a-real-password-2026")
    assert blocked.status_code == 429

    # The guard does not persist the plain-text email, hash or password.
    with SessionLocal() as db:
        rows = db.scalars(select(LoginAttempt)).all()
        assert len(rows) == 2
        assert {row.key for row in rows} == {_login_key(account), _login_key(missing)}
        assert all(row.failed_count == LOGIN_FAILURE_LIMIT for row in rows)
        assert all(len(row.key) == 64 for row in rows)
        assert all("@" not in row.key for row in rows)
        assert all(row.blocked_until is not None for row in rows)


def test_success_resets_failed_count_and_other_account_can_log_in(client):
    register(client, "alpha@medisuvi-ci.org")
    register(client, "beta@medisuvi-ci.org")
    for _ in range(3):
        assert attempt(client, "alpha@medisuvi-ci.org", "invalid").status_code == 401
    assert attempt(client, "beta@medisuvi-ci.org",
                   "not-a-real-password-2026").status_code == 200
    assert attempt(client, "alpha@medisuvi-ci.org",
                   "not-a-real-password-2026").status_code == 200
    with SessionLocal() as db:
        row = db.get(LoginAttempt, _login_key("alpha@medisuvi-ci.org"))
        assert row.failed_count == 0
        assert row.blocked_until is None
    assert attempt(client, "alpha@medisuvi-ci.org", "wrong").status_code == 401
    with SessionLocal() as db:
        assert db.get(LoginAttempt, _login_key("alpha@medisuvi-ci.org")).failed_count == 1


def test_lock_persists_when_failure_window_expires_and_unlocks_on_timeout(client):
    email = "locked@medisuvi-ci.org"
    register(client, email)
    for _ in range(LOGIN_FAILURE_LIMIT):
        attempt(client, email, "wrong")
    with SessionLocal() as db:
        row = db.get(LoginAttempt, _login_key(email))
        # Simulate first failure long ago but the 15-minute lock is still active.
        row.window_started_at = datetime.now(timezone.utc) - timedelta(hours=1)
        row.blocked_until = datetime.now(timezone.utc) + timedelta(minutes=7)
        db.commit()
    assert attempt(client, email, "not-a-real-password-2026").status_code == 429

    with SessionLocal() as db:
        row = db.get(LoginAttempt, _login_key(email))
        row.blocked_until = datetime.now(timezone.utc) - timedelta(seconds=2)
        db.commit()

    good = attempt(client, email, "not-a-real-password-2026")
    assert good.status_code == 200, good.text
    with SessionLocal() as db:
        row = db.get(LoginAttempt, _login_key(email))
        assert row.failed_count == 0
        assert row.blocked_until is None


def test_email_case_variants_share_single_guard(client):
    register(client, "case@medisuvi-ci.org")
    for _ in range(3):
        assert attempt(client, "CASE@medisuvi-ci.org", "bad").status_code == 401
    for n in range(2):
        response = attempt(client, "case@medisuvi-ci.org", "bad")
        assert response.status_code == (429 if n == 1 else 401)
    with SessionLocal() as db:
        rows = db.scalars(select(LoginAttempt)).all()
        assert len(rows) == 1


def test_registration_and_other_accounts_remain_available_after_lock(client):
    email = "attacked@medisuvi-ci.org"
    register(client, email)
    for _ in range(LOGIN_FAILURE_LIMIT):
        attempt(client, email, "incorrect")
    # No global lock across practitioners: private independent sessions.
    register(client, "unaffected@medisuvi-ci.org")
    assert attempt(client, "unaffected@medisuvi-ci.org",
                   "not-a-real-password-2026").status_code == 200
