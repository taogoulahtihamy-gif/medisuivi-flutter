"""Full synthetic clinical roundtrip using real PostgreSQL 17.

CI migrates its fresh PostgreSQL database before this test. A new TestClient
simulates closing and reopening the Flutter app: clinical records must remain
in PostgreSQL and must remain invisible to the other signed-in practitioner.
"""
from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import app, engine, settings


def _register(client, email):
    response = client.post("/api/v1/auth/register", json={
        "email": email, "password": "synthetic-only-strong-password-2026",
        "first_name": "Médecin", "last_name": "Fictif",
    })
    assert response.status_code == 201, response.text


def _login(client, email):
    response = client.post("/api/v1/auth/login", json={
        "email": email, "password": "synthetic-only-strong-password-2026",
    })
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _get(client, path, headers):
    response = client.get(path, headers=headers)
    assert response.status_code == 200, response.text
    return response.json()


def test_clinical_records_survive_relogin_and_remain_strictly_private(monkeypatch):
    assert engine.dialect.name == "postgresql"
    with engine.connect() as connection:
        assert connection.execute(text("SELECT version_num FROM alembic_version")).scalar() == "0005"
    monkeypatch.setattr(settings, "environment", "development")
    monkeypatch.setattr(settings, "allow_registration", True)
    monkeypatch.setattr(settings, "email_auth_enabled", False)

    address_a = "clinical-roundtrip-a@medisuvi-ci.org"
    address_b = "clinical-roundtrip-b@medisuvi-ci.org"
    with TestClient(app) as first:
        _register(first, address_a)
        _register(first, address_b)
        a, b = _login(first, address_a), _login(first, address_b)
        own = first.post("/api/v1/patients", headers=a,
                         json={"display_name": "PATIENT SYNTHETIQUE A", "age": 33})
        other = first.post("/api/v1/patients", headers=b,
                           json={"display_name": "PATIENT SYNTHETIQUE B", "age": 44})
        assert own.status_code == other.status_code == 201
        patient_a = own.json()["id"]
        patient_b = other.json()["id"]
        assert patient_a != patient_b

        root = f"/api/v1/patients/{patient_a}"
        assert first.post(root + "/visits", headers=b,
            json={"reason":"Cross-owner forbidden"}).status_code == 404

        visit = first.post(root + "/visits", headers=a, json={
            "reason": "Contrôle clinique fictif avec constantes",
            "temperature": 36.8, "systolic": 120, "diastolic": 80,
            "pulse": 72, "spo2": 98, "notes": "Données fictives",
        })
        assert visit.status_code == 201, visit.text
        assert visit.json()["temperature"] == 36.8

        exam = first.post(root + "/exams", headers=a, json={
            "title": "Examen de démonstration",
        })
        assert exam.status_code == 201, exam.text
        exam_id = exam.json()["id"]
        forbidden = first.put(f"/api/v1/exams/{exam_id}/result",
            headers=b, json={"result": "Forbidden"})
        assert forbidden.status_code == 404
        result = first.put(f"/api/v1/exams/{exam_id}/result", headers=a,
            json={"result": "Résultat de démonstration sans valeur médicale"})
        assert result.status_code == 200, result.text

        date = datetime.now(timezone.utc) + timedelta(days=8)
        followup = first.post(root + "/followups", headers=a, json={
            "scheduled_at": date.isoformat(), "reason": "Contrôle fictif",
        })
        assert followup.status_code == 201, followup.text
        followup_id = followup.json()["id"]
        moved = first.put(f"/api/v1/followups/{followup_id}/reschedule",
            headers=a, json={
                "scheduled_at": (date + timedelta(days=7)).isoformat(),
                "reason": "Contrôle fictif", "notes": "Report de démonstration",
            })
        assert moved.status_code == 200, moved.text
        assert first.put(f"/api/v1/followups/{followup_id}/reschedule",
            headers=b, json={
                "scheduled_at": date.isoformat(),
                "reason": "Forbidden",
            }).status_code == 404

        assert first.post("/api/v1/auth/logout", headers=a).status_code == 204
        assert first.get(root + "/visits", headers=a).status_code == 401

    # New client, fresh bearer tokens, real PostgreSQL rows unchanged.
    with TestClient(app) as reopened:
        a, b = _login(reopened, address_a), _login(reopened, address_b)
        own_patients = _get(reopened, "/api/v1/patients", a)
        other_patients = _get(reopened, "/api/v1/patients", b)
        assert [p["id"] for p in own_patients] == [patient_a]
        assert [p["id"] for p in other_patients] == [patient_b]

        assert reopened.get(f"/api/v1/patients/{patient_a}",
                            headers=b).status_code == 404
        root = f"/api/v1/patients/{patient_a}"
        visits = _get(reopened, root + "/visits", a)
        exams = _get(reopened, root + "/exams", a)
        followups = _get(reopened, root + "/followups", a)
        assert len(visits) == len(exams) == len(followups) == 1
        assert visits[0]["temperature"] == 36.8
        assert visits[0]["systolic"] == 120
        assert exams[0]["status"] == "complete"
        assert exams[0]["result"] == "Résultat de démonstration sans valeur médicale"
        assert followups[0]["scheduled_at"] != date.isoformat()

        for kind in ["visits", "exams", "followups"]:
            assert reopened.get(root + "/" + kind, headers=b).status_code == 404

        assert reopened.put(f"/api/v1/followups/{followup_id}/close",
            headers=b, json={"completed": True}).status_code == 404
        closed = reopened.put(f"/api/v1/followups/{followup_id}/close",
            headers=a, json={"completed": False})
        assert closed.status_code == 200, closed.text
        assert closed.json()["status"] == "cancelled"
        assert _get(reopened, root + "/followups", a)[0]["status"] == "cancelled"
