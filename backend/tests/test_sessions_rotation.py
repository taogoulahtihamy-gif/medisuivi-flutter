"""Per-device JWT session isolation and refresh-token rotation tests."""
import hashlib
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from test_auth_isolation import client, fresh_database, login, register  # noqa: F401
from app.main import AuthSession, SessionLocal, User


def credentials(client, email):
    response = client.post("/api/v1/auth/login", json={
        "email": email, "password": "not-a-real-password-2026"})
    assert response.status_code == 200, response.text
    return response.json()


def auth(token):
    return {"Authorization": "Bearer " + token["access_token"]}


def test_each_device_can_log_out_without_revoking_other_sessions(client):
    register(client, "dev-a@medisuvi-ci.org")
    a = credentials(client, "dev-a@medisuvi-ci.org")
    b = credentials(client, "dev-a@medisuvi-ci.org")
    assert a["access_token"] != b["access_token"]
    assert a["refresh_token"] != b["refresh_token"]
    with SessionLocal() as db:
        rows = db.scalars(select(AuthSession)).all()
        assert len(rows) == 2
        assert a["refresh_token"] not in [x.refresh_digest for x in rows]
        assert all(len(x.refresh_digest) == 64 for x in rows)
    assert client.get("/api/v1/me", headers=auth(a)).status_code == 200
    assert client.get("/api/v1/me", headers=auth(b)).status_code == 200
    assert client.post("/api/v1/auth/logout", headers=auth(a)).status_code == 204
    assert client.get("/api/v1/me", headers=auth(a)).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={
        "refresh_token": a["refresh_token"]}).status_code == 401
    assert client.get("/api/v1/me", headers=auth(b)).status_code == 200


def test_rotated_refresh_token_replay_revokes_only_the_compromised_session(client):
    register(client, "replay@medisuvi-ci.org")
    a = credentials(client, "replay@medisuvi-ci.org")
    b = credentials(client, "replay@medisuvi-ci.org")
    refreshed = client.post("/api/v1/auth/refresh", json={
        "refresh_token": a["refresh_token"]})
    assert refreshed.status_code == 200, refreshed.text
    new = refreshed.json()
    assert new["refresh_token"] != a["refresh_token"]
    assert client.get("/api/v1/me", headers=auth(new)).status_code == 200
    # Old credential reused: this session is now revoked (replay alarm).
    assert client.post("/api/v1/auth/refresh", json={
        "refresh_token": a["refresh_token"]}).status_code == 401
    assert client.get("/api/v1/me", headers=auth(new)).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={
        "refresh_token": new["refresh_token"]}).status_code == 401
    # Another device remains unaffected.
    assert client.get("/api/v1/me", headers=auth(b)).status_code == 200


def test_random_bad_refresh_token_does_not_revoke_known_session(client):
    register(client, "bad-refresh@medisuvi-ci.org")
    token = credentials(client, "bad-refresh@medisuvi-ci.org")
    session_id = token["refresh_token"].split(".")[0]
    invalid = session_id + "." + "X" * 64
    assert client.post("/api/v1/auth/refresh", json={
        "refresh_token": invalid}).status_code == 401
    assert client.get("/api/v1/me", headers=auth(token)).status_code == 200


def test_logout_all_invalidates_every_existing_device(client):
    register(client, "all@medisuvi-ci.org")
    a = credentials(client, "all@medisuvi-ci.org")
    b = credentials(client, "all@medisuvi-ci.org")
    assert client.post("/api/v1/auth/logout-all",
                       headers=auth(a)).status_code == 204
    for token in [a, b]:
        assert client.get("/api/v1/me", headers=auth(token)).status_code == 401
        assert client.post("/api/v1/auth/refresh", json={
            "refresh_token": token["refresh_token"]}).status_code == 401
    fresh = credentials(client, "all@medisuvi-ci.org")
    assert client.get("/api/v1/me", headers=auth(fresh)).status_code == 200


def test_session_expiry_and_cross_user_tokens_do_not_leak(client):
    register(client, "a@medisuvi-ci.org")
    register(client, "b@medisuvi-ci.org")
    a = credentials(client, "a@medisuvi-ci.org")
    b = credentials(client, "b@medisuvi-ci.org")
    patient = client.post("/api/v1/patients", headers=auth(a),
                          json={"display_name":"FICTIF X", "age":30})
    assert patient.status_code == 201
    pid = patient.json()["id"]
    assert client.get(f"/api/v1/patients/{pid}", headers=auth(b)).status_code == 404

    with SessionLocal() as db:
        row = db.scalar(select(AuthSession).where(
            AuthSession.id == a["refresh_token"].split(".")[0]))
        row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
        db.commit()
    assert client.get("/api/v1/me", headers=auth(a)).status_code == 401
    assert client.post("/api/v1/auth/refresh", json={
        "refresh_token": a["refresh_token"]}).status_code == 401
    assert client.get("/api/v1/me", headers=auth(b)).status_code == 200
