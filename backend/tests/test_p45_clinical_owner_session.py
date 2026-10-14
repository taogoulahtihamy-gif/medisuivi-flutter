"""P4.5: synthetic multi-practitioner clinical API regression on disposable PG.

This file is CI-only. Never run it against the local database that contains
existing clinical records, even fictitious ones.
"""
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.main import (
    LabExam, Patient, SessionLocal, User, Visit, FollowUp,
    app, engine, settings,
)

PASSWORD = "synthetic-p45-password-only-2026"


def _require_disposable_postgres(monkeypatch):
    # Abort BEFORE registration or any clinical writes on a real/staging DB.
    assert engine.dialect.name == "postgresql"
    assert engine.url.database == "medisuivi_ci", (
        "P4.5 tests require the isolated medisuivi_ci CI database"
    )
    with engine.connect() as connection:
        assert connection.execute(
            text("SELECT version_num FROM alembic_version")
        ).scalar_one() == "0006"
    monkeypatch.setattr(settings, "environment", "development")
    monkeypatch.setattr(settings, "allow_registration", True)
    monkeypatch.setattr(settings, "email_auth_enabled", False)


def _create_user(client, prefix):
    email = f"{prefix}-{uuid4().hex}@medisuvi-ci.org"
    response = client.post("/api/v1/auth/register", json={
        "email": email, "password": PASSWORD,
        "first_name": "Compte", "last_name": "Fictif",
    })
    assert response.status_code == 201, response.text
    return email


def _sign_in(client, email):
    response = client.post("/api/v1/auth/login", json={
        "email": email, "password": PASSWORD,
    })
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _created(client, path, headers, payload):
    response = client.post(path, headers=headers, json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def test_account_switch_relogin_and_clinical_data_remain_isolated(monkeypatch):
    _require_disposable_postgres(monkeypatch)

    with TestClient(app) as client:
        email_a = _create_user(client, "p45-owner-a")
        email_b = _create_user(client, "p45-owner-b")
        owner_a = _sign_in(client, email_a)
        owner_b = _sign_in(client, email_b)

        patient_a = _created(client, "/api/v1/patients", owner_a, {
            "display_name": "PATIENT FICTIF P45 A", "age": 30,
        })["id"]
        patient_b = _created(client, "/api/v1/patients", owner_b, {
            "display_name": "PATIENT FICTIF P45 B", "age": 31,
        })["id"]
        root_a = f"/api/v1/patients/{patient_a}"

        visit = _created(client, root_a + "/visits", owner_a, {
            "reason": "Visite fictive de sécurité",
            "temperature": 37.1, "pulse": 71,
            "notes": "Valeurs synthétiques seulement",
        })
        exam = _created(client, root_a + "/exams", owner_a, {
            "title": "Analyse fictive",
        })
        when = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
        followup = _created(client, root_a + "/followups", owner_a, {
            "scheduled_at": when, "reason": "Suivi fictif",
        })

        # Switching a practitioner must not expose the previous account's
        # patient list or nested clinical records.
        for headers, expected in [(owner_a, patient_a), (owner_b, patient_b)]:
            response = client.get("/api/v1/patients", headers=headers)
            assert response.status_code == 200
            assert [p["id"] for p in response.json()] == [expected]

        assert client.get("/api/v1/patients").status_code == 401
        assert client.get(root_a, headers=owner_b).status_code == 404
        for kind in ("visits", "exams", "followups"):
            assert client.get(root_a + "/" + kind, headers=owner_b).status_code == 404

        # Rejected cross-owner writes must not alter A's existing data.
        assert client.post(root_a + "/visits", headers=owner_b,
                           json={"reason": "blocked"}).status_code == 404
        assert client.put(
            f"/api/v1/exams/{exam['id']}/result",
            headers=owner_b, json={"result": "blocked"},
        ).status_code == 404
        assert client.put(
            f"/api/v1/followups/{followup['id']}/close",
            headers=owner_b, json={"completed": True},
        ).status_code == 404

        with SessionLocal() as session:
            db_user_a = session.scalar(select(User).where(User.email == email_a))
            assert db_user_a is not None
            assert session.get(Patient, patient_a).owner_user_id == db_user_a.id
            for model, child_id in (
                (Visit, visit["id"]), (LabExam, exam["id"]),
                (FollowUp, followup["id"]),
            ):
                row = session.get(model, child_id)
                assert row.owner_user_id == db_user_a.id
                assert row.patient_id == patient_a

        assert client.post("/api/v1/auth/logout", headers=owner_a).status_code == 204
        assert client.get(root_a, headers=owner_a).status_code == 401
        # Revoking A's session must not affect B.
        assert client.get("/api/v1/patients", headers=owner_b).status_code == 200

    # A new HTTP client models an app restart. Records remain in PostgreSQL.
    with TestClient(app) as restarted:
        new_a = _sign_in(restarted, email_a)
        new_b = _sign_in(restarted, email_b)
        assert restarted.get(root_a, headers=new_b).status_code == 404

        def records(kind):
            response = restarted.get(root_a + "/" + kind, headers=new_a)
            assert response.status_code == 200, response.text
            return response.json()

        assert [v["id"] for v in records("visits")] == [visit["id"]]
        assert records("visits")[0]["notes"] == "Valeurs synthétiques seulement"
        assert [e["id"] for e in records("exams")] == [exam["id"]]
        assert records("exams")[0]["status"] == "pending"
        assert [f["id"] for f in records("followups")] == [followup["id"]]
        assert records("followups")[0]["status"] == "planned"


def test_owner_spoofing_and_anonymous_writes_are_rejected(monkeypatch):
    _require_disposable_postgres(monkeypatch)

    with TestClient(app) as client:
        email = _create_user(client, "p45-spoof")
        token = _sign_in(client, email)

        assert client.post("/api/v1/patients", json={
            "display_name": "ANONYMOUS FAKE", "age": 24,
        }).status_code == 401

        with SessionLocal() as session:
            owner_id = session.scalar(select(User.id).where(User.email == email))
        assert owner_id

        # The client must never dictate owner_user_id, including its own ID.
        assert client.post("/api/v1/patients", headers=token, json={
            "display_name": "SPOOFED FAKE", "age": 24,
            "owner_user_id": owner_id,
        }).status_code == 422

        patient = _created(client, "/api/v1/patients", token, {
            "display_name": "PATIENT FICTIF SÛR", "age": 24,
        })["id"]
        for kind, payload in (
            ("visits", {"reason": "Fictif"}),
            ("exams", {"title": "Fictif"}),
            ("followups", {
                "scheduled_at": datetime.now(timezone.utc).isoformat(),
                "reason": "Fictif",
            }),
        ):
            assert client.post(
                f"/api/v1/patients/{patient}/{kind}",
                headers=token, json={**payload, "owner_user_id": owner_id},
            ).status_code == 422
            assert client.get(
                f"/api/v1/patients/{patient}/{kind}", headers=token
            ).json() == []
