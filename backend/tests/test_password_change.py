"""Synthetic-only authenticated password rotation and session isolation tests."""
from sqlalchemy import select

from test_auth_isolation import client, fresh_database, register  # noqa: F401
from test_sessions_rotation import credentials, auth
from app.main import SessionLocal, User, hasher, settings


def change(client, headers, old, new):
    return client.put("/api/v1/me/password", headers=headers, json={
        "current_password": old, "new_password": new,
    })


def test_password_change_revokes_all_devices_and_old_credentials(client):
    email = "password-change@medisuvi-ci.org"
    practitioner = register(client, email)
    device_a = credentials(client, email)
    device_b = credentials(client, email)
    new = "new-long-secret-for-ci-2026"
    result = change(client, auth(device_a), "not-a-real-password-2026", new)
    assert result.status_code == 204, result.text
    with SessionLocal() as db:
        user = db.get(User, practitioner["id"])
        assert user.session_version == 1
        assert user.password_hash != new
        assert user.password_hash.startswith("$argon2id$")
        assert hasher.verify(user.password_hash, new)

    for token in (device_a, device_b):
        assert client.get("/api/v1/me", headers=auth(token)).status_code == 401
        assert client.post("/api/v1/auth/refresh", json={
            "refresh_token": token["refresh_token"],
        }).status_code == 401
    old_login = client.post("/api/v1/auth/login", json={
        "email": email, "password": "not-a-real-password-2026",
    })
    assert old_login.status_code == 401
    new_login = client.post("/api/v1/auth/login", json={
        "email": email, "password": new,
    })
    assert new_login.status_code == 200
    assert client.get("/api/v1/me", headers=auth(new_login.json())).status_code == 200


def test_wrong_current_password_keeps_all_sessions_and_hash(client):
    email = "bad-current@medisuvi-ci.org"
    p = register(client, email)
    device = credentials(client, email)
    with SessionLocal() as db:
        old_hash = db.get(User, p["id"]).password_hash
    result = change(client, auth(device), "wrong-old",
                    "another-new-long-password-2026")
    assert result.status_code == 400
    assert result.json() == {"detail": "Mot de passe actuel incorrect"}
    assert client.get("/api/v1/me", headers=auth(device)).status_code == 200
    with SessionLocal() as db:
        assert db.get(User, p["id"]).password_hash == old_hash


def test_old_password_cannot_be_reused_and_password_strength_enforced(client):
    email = "reuse@medisuvi-ci.org"
    register(client, email)
    device = credentials(client, email)
    same = change(client, auth(device),
                  "not-a-real-password-2026", "not-a-real-password-2026")
    assert same.status_code == 422
    weak = change(client, auth(device), "not-a-real-password-2026", "short")
    assert weak.status_code == 422
    forbidden = client.put("/api/v1/me/password", headers=auth(device), json={
        "current_password": "not-a-real-password-2026",
        "new_password": "new-long-enough-secret",
        "user_id": "someone-else",
    })
    assert forbidden.status_code == 422
    assert client.get("/api/v1/me", headers=auth(device)).status_code == 200


def test_changing_password_does_not_affect_other_practitioners(client):
    register(client, "one@medisuvi-ci.org")
    register(client, "two@medisuvi-ci.org")
    a = credentials(client, "one@medisuvi-ci.org")
    b = credentials(client, "two@medisuvi-ci.org")
    assert change(client, auth(a), "not-a-real-password-2026",
                  "one-new-password-2026").status_code == 204
    assert client.get("/api/v1/me", headers=auth(a)).status_code == 401
    assert client.get("/api/v1/me", headers=auth(b)).status_code == 200


def test_password_change_respects_fail_closed_and_login_rate_limit(client, monkeypatch):
    email = "lock-password@medisuvi-ci.org"
    register(client, email)
    device = credentials(client, email)
    for i in range(5):
        response = change(client, auth(device), "wrong-current",
                          "fresh-password-that-is-long")
        assert response.status_code == (429 if i == 4 else 401)
    correct = change(client, auth(device), "not-a-real-password-2026",
                     "fresh-password-that-is-long")
    assert correct.status_code == 429
    monkeypatch.setattr(settings, "environment", "staging")
    blocked = change(client, auth(device), "not-a-real-password-2026",
                     "new-password-that-is-long")
    assert blocked.status_code == 403


def test_password_endpoint_requires_authentication(client):
    request = client.put("/api/v1/me/password", json={
        "current_password": "not-a-real-password-2026",
        "new_password": "another-new-strong-password",
    })
    assert request.status_code == 401
