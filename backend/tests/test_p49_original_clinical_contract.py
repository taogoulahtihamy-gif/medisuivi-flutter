"""P4.9: the original MediSuivi screens persist all synthetic clinical data.

Runs only on disposable medisuivi_ci PostgreSQL after revision 0006.
No real medical data or real credentials. Cross-practitioner isolation is
enforced by both the API and the composite owner FK.
"""
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import app, engine, settings

PASSWORD = "p49-synthetic-test-password-long-enough"


def _sign_in(client, email):
    response = client.post("/api/v1/auth/login", json={
        "email": email, "password": PASSWORD,
    })
    assert response.status_code == 200, response.text
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def _register(client, prefix):
    email = f"{prefix}-{uuid4().hex}@medisuvi-ci.org"
    response = client.post("/api/v1/auth/register", json={
        "email": email, "password": PASSWORD,
        "first_name": "Compte", "last_name": "Synthétique",
    })
    assert response.status_code == 201, response.text
    return email


def test_original_patient_profile_intake_roundtrip_and_account_privacy(monkeypatch):
    assert engine.dialect.name == "postgresql"
    assert engine.url.database == "medisuivi_ci"
    with engine.connect() as db:
        assert db.execute(
            text("SELECT version_num FROM alembic_version")
        ).scalar_one() == "0006"

    monkeypatch.setattr(settings, "environment", "development")
    monkeypatch.setattr(settings, "allow_registration", True)
    monkeypatch.setattr(settings, "email_auth_enabled", False)

    profile = {
        "neighborhood": "QUARTIER SYNTHÉTIQUE",
        "address": "ADRESSE FICTIVE",
        "emergencyContactName": "CONTACT FICTIF",
        "emergencyContactPhone": "000000000",
        "currentMedications": "",
        "surgicalHistory": "",
        "familyHistory": "",
    }
    intake = {
        "schemaVersion": 1,
        "weightKg": 71.0,
        "heightCm": 173.0,
        "respiratoryRate": 18,
        "symptomHistory": "SYMPTÔMES FICTIFS",
        "associatedSigns": "",
        "generalCondition": "",
        "physicalExamination": "",
        "systemsExamination": "",
        "diagnosticHypotheses": "",
        "diagnosis": "",
        "investigationsRequested": "",
        "investigationsInterpretation": "",
        "managementPlan": "",
        "outpatientTreatment": "",
        "hospitalizationReason": "",
        "referralDetails": "",
        "followUpInstructions": "",
        "careDisposition": "undecided",
    }

    with TestClient(app) as client:
        email_a, email_b = _register(client, "p49-a"), _register(client, "p49-b")
        a, b = _sign_in(client, email_a), _sign_in(client, email_b)

        created = client.post("/api/v1/patients", headers=a, json={
            "display_name": "PATIENT FICTIF P49",
            "age": 37,
            "sex": "F",
            "phone": "000000000",
            "profile_json": profile,
        })
        assert created.status_code == 201, created.text
        patient = created.json()
        pid = patient["id"]
        assert patient["sex"] == "F"
        assert patient["profile_json"] == profile
        assert patient["created_at"]
        assert client.get(f"/api/v1/patients/{pid}", headers=b).status_code == 404

        update = client.put(f"/api/v1/patients/{pid}", headers=a, json={
            "phone": "000111111",
            "allergies": "AUCUNE (FICTIF)",
            "medical_history": "ANTÉCÉDENT FICTIF",
            "profile_json": profile,
        })
        assert update.status_code == 200, update.text
        assert update.json()["medical_history"] == "ANTÉCÉDENT FICTIF"
        assert client.put(f"/api/v1/patients/{pid}", headers=b,
            json={"phone": "x", "allergies": "", "medical_history": ""}).status_code == 404
        assert client.put(f"/api/v1/patients/{pid}/follow-up-flag", headers=b,
            json={"to_review": True}).status_code == 404

        marked = client.put(f"/api/v1/patients/{pid}/follow-up-flag",
            headers=a, json={"to_review": True})
        assert marked.status_code == 200
        assert marked.json()["follow_up"] is True

        saved = client.post(f"/api/v1/patients/{pid}/visits", headers=a, json={
            "reason": "VISITE SYNTHÉTIQUE",
            "temperature": 36.9, "pulse": 72,
            "notes": "NOTE FICTIVE", "intake_json": intake,
        })
        assert saved.status_code == 201, saved.text
        assert saved.json()["intake_json"] == intake
        assert client.post(f"/api/v1/patients/{pid}/visits", headers=b,
            json={"reason": "NOT YOUR RECORD"}).status_code == 404

        exam = client.post(f"/api/v1/patients/{pid}/exams",
            headers=a, json={"title": "EXAMEN SYNTHÉTIQUE"})
        assert exam.status_code == 201
        when = (datetime.now(timezone.utc) + timedelta(days=10)).isoformat()
        follow = client.post(f"/api/v1/patients/{pid}/followups",
            headers=a, json={"reason": "SUIVI FICTIF", "scheduled_at": when})
        assert follow.status_code == 201

        assert client.post("/api/v1/auth/logout", headers=a).status_code == 204
        assert client.get(f"/api/v1/patients/{pid}", headers=a).status_code == 401

    with TestClient(app) as restarted:
        a = _sign_in(restarted, email_a)
        b = _sign_in(restarted, email_b)
        stored = restarted.get(f"/api/v1/patients/{pid}", headers=a)
        assert stored.status_code == 200
        assert stored.json()["follow_up"] is True
        assert stored.json()["allergies"] == "AUCUNE (FICTIF)"
        assert stored.json()["profile_json"] == profile
        assert restarted.get(f"/api/v1/patients/{pid}", headers=b).status_code == 404
        rows = restarted.get(
            f"/api/v1/patients/{pid}/visits", headers=a).json()
        assert rows[0]["intake_json"] == intake
        assert rows[0]["notes"] == "NOTE FICTIVE"
        assert len(restarted.get(
            f"/api/v1/patients/{pid}/exams", headers=a).json()) == 1
        assert len(restarted.get(
            f"/api/v1/patients/{pid}/followups", headers=a).json()) == 1
        for kind in ("visits", "exams", "followups"):
            assert restarted.get(
                f"/api/v1/patients/{pid}/{kind}", headers=b).status_code == 404

        # Old synthetic client payloads without new fields remain compatible.
        old = restarted.post("/api/v1/patients", headers=a, json={
            "display_name": "HISTORIQUE FICTIF", "age": 21})
        assert old.status_code == 201
        assert old.json()["sex"] == "N"
        assert old.json()["phone"] == ""

        # Unknown profile fields and spoofed owners are always rejected.
        assert restarted.post("/api/v1/patients", headers=a, json={
            "display_name": "REJETÉ", "age": 30,
            "owner_user_id": pid,
        }).status_code == 422
        assert restarted.post("/api/v1/patients", headers=a, json={
            "display_name": "REJETÉ", "age": 30,
            "profile_json": {"secret_unknown_field": "x"},
        }).status_code == 422
        assert restarted.post(f"/api/v1/patients/{pid}/visits",
            headers=a, json={"reason": "REJETÉ", "intake_json": {
                "schemaVersion": 99,
            }}).status_code == 422
