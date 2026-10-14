"""API security regression: never leak A's clinical records to practitioner B.

All data is synthetic. Auth and database are deliberately shared with the
P1 test module to exercise the exact same middleware/dependencies.
"""
from datetime import datetime, timedelta, timezone

import pytest

from test_auth_isolation import client, fresh_database, login, register  # noqa: F401
from app.main import (
    FollowUp, LabExam, Patient, SessionLocal, User, Visit,
)
from sqlalchemy.exc import IntegrityError


@pytest.fixture
def accounts(client):
    a = register(client, "dr.alpha@medisuvi-ci.org")
    b = register(client, "dr.beta@medisuvi-ci.org")
    headers_a = login(client, a["email"])
    headers_b = login(client, b["email"])
    p_a = client.post("/api/v1/patients", headers=headers_a,
        json={"display_name": "PATIENT SYNTHETIQUE ALPHA", "age": 35})
    p_b = client.post("/api/v1/patients", headers=headers_b,
        json={"display_name": "PATIENT SYNTHETIQUE BETA", "age": 44})
    assert p_a.status_code == p_b.status_code == 201
    return headers_a, headers_b, p_a.json()["id"], p_b.json()["id"], a["id"], b["id"]


def must_404(response):
    assert response.status_code == 404, response.text
    assert "SYNTHETIQUE" not in response.text


def test_visits_create_list_private_parent_and_owner(accounts, client):
    a, b, pa, pb, _, _ = accounts
    url = f"/api/v1/patients/{pa}/visits"
    record = {"reason": "Consultation fictive", "temperature": 37.2,
              "systolic": 123, "diastolic": 82, "spo2": 98, "notes": "Test"}
    assert client.post(url, headers=b, json=record).status_code == 404
    created = client.post(url, headers=a, json=record)
    assert created.status_code == 201, created.text
    assert created.json()["reason"] == "Consultation fictive"
    assert created.json()["patient_id"] == pa
    assert "owner_user_id" not in created.json()
    assert len(client.get(url, headers=a).json()) == 1
    must_404(client.get(url, headers=b))
    assert client.get(f"/api/v1/patients/{pb}/visits", headers=b).json() == []
    assert client.post(url, headers=a, json=record | {
        "owner_user_id": "forged"
    }).status_code == 422
    assert client.post(url, headers=a, json={
        "reason": "Non valide", "spo2": 101
    }).status_code == 422


def test_lab_exams_cannot_be_seen_or_updated_across_practitioners(accounts, client):
    a, b, pa, _, _, _ = accounts
    url = f"/api/v1/patients/{pa}/exams"
    must_404(client.post(url, headers=b, json={"title": "Test interdit"}))
    created = client.post(url, headers=a, json={"title": "Numération fictive"})
    assert created.status_code == 201, created.text
    exam_id = created.json()["id"]
    assert created.json()["status"] == "pending"
    must_404(client.get(url, headers=b))
    assert len(client.get(url, headers=a).json()) == 1
    must_404(client.put(f"/api/v1/exams/{exam_id}/result", headers=b,
                            json={"result": "accès non autorisé"}))
    done = client.put(f"/api/v1/exams/{exam_id}/result", headers=a,
                      json={"result": "Résultat SYNTHETIQUE normal"})
    assert done.status_code == 200, done.text
    assert done.json()["status"] == "complete"
    assert done.json()["result_recorded_at"] is not None
    assert client.put(f"/api/v1/exams/{exam_id}/result", headers=a,
                      json={"result": "écrasement"}).status_code == 409
    assert client.post(url, headers=a, json={
        "title": "Invalide", "status": "complete"
    }).status_code == 422


def test_followups_schedule_reschedule_close_are_private(accounts, client):
    a, b, pa, _, _, _ = accounts
    url = f"/api/v1/patients/{pa}/followups"
    now = datetime.now(timezone.utc) + timedelta(days=3)
    payload = {"scheduled_at": now.isoformat(), "reason": "Visite de contrôle",
               "notes": "rendez-vous fictif"}
    must_404(client.post(url, headers=b, json=payload))
    created = client.post(url, headers=a, json=payload)
    assert created.status_code == 201, created.text
    fid = created.json()["id"]
    assert created.json()["status"] == "planned"
    assert len(client.get(url, headers=a).json()) == 1
    must_404(client.get(url, headers=b))

    res_url = f"/api/v1/followups/{fid}/reschedule"
    close_url = f"/api/v1/followups/{fid}/close"
    moved = payload | {"scheduled_at": (now + timedelta(days=7)).isoformat()}
    must_404(client.put(res_url, headers=b, json=moved))
    must_404(client.put(close_url, headers=b, json={"completed": False}))
    assert client.put(res_url, headers=a, json=moved).status_code == 200

    closed = client.put(close_url, headers=a, json={"completed": True})
    assert closed.status_code == 200, closed.text
    assert closed.json()["status"] == "completed"
    assert closed.json()["completed_at"] is not None
    assert client.put(close_url, headers=a, json={"completed": False}).status_code == 409
    assert client.put(res_url, headers=a, json=moved).status_code == 409
    assert client.post(url, headers=a, json=payload | {
        "scheduled_at": "2026-12-10T14:00:00"
    }).status_code == 422


def test_direct_database_injection_cannot_cross_owner(accounts):
    _, _, pa, _, uid_a, uid_b = accounts
    with SessionLocal() as session:
        # Composite FK (patient_id, owner_user_id) blocks even malicious SQLAlchemy writes.
        attempts = [
            Visit(patient_id=pa, owner_user_id=uid_b, reason="Forbidden"),
            LabExam(patient_id=pa, owner_user_id=uid_b, title="Forbidden"),
            FollowUp(patient_id=pa, owner_user_id=uid_b,
                reason="Forbidden", scheduled_at=datetime.now(timezone.utc)),
        ]
        for entry in attempts:
            session.add(entry)
            with pytest.raises(IntegrityError):
                session.flush()
            session.rollback()
        assert session.query(Visit).count() == 0
        assert session.query(LabExam).count() == 0
        assert session.query(FollowUp).count() == 0


def test_anonymous_and_revoked_token_cannot_use_clinical_api(accounts, client):
    a, _, pa, _, _, _ = accounts
    clinical = [
        f"/api/v1/patients/{pa}/visits",
        f"/api/v1/patients/{pa}/exams",
        f"/api/v1/patients/{pa}/followups",
    ]
    for endpoint in clinical:
        assert client.get(endpoint).status_code == 401
    assert client.post("/api/v1/auth/logout", headers=a).status_code == 204
    for endpoint in clinical:
        assert client.get(endpoint, headers=a).status_code == 401


def test_non_development_blocks_every_clinical_write(accounts, client, monkeypatch):
    from app.main import settings
    a, _, pa, _, _, _ = accounts
    monkeypatch.setattr(settings, "environment", "staging")
    root = f"/api/v1/patients/{pa}"
    assert client.post(root + "/visits", headers=a,
                       json={"reason": "blocked"}).status_code == 403
    assert client.post(root + "/exams", headers=a,
                       json={"title": "blocked"}).status_code == 403
    assert client.post(root + "/followups", headers=a, json={
        "scheduled_at": datetime.now(timezone.utc).isoformat(),
        "reason": "blocked"
    }).status_code == 403
