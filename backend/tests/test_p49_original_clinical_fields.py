"""P4.9.1 synthetic extended clinical fields, PostgreSQL CI only."""
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import app, engine, settings


def _test_db_only(monkeypatch):
    assert engine.dialect.name == "postgresql"
    assert engine.url.database == "medisuivi_ci"
    with engine.connect() as con:
        assert con.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0006"
    monkeypatch.setattr(settings, "environment", "development")
    monkeypatch.setattr(settings, "allow_registration", True)
    monkeypatch.setattr(settings, "email_auth_enabled", False)


def _new_owner(client, suffix):
    email = f"p49-{suffix}-{uuid4().hex}@medisuvi-ci.org"
    password = "P49-only-synthetic-password-2026"
    res = client.post("/api/v1/auth/register", json={
        "email": email, "password": password,
        "first_name": "Praticien", "last_name": "Fictif",
    })
    assert res.status_code == 201, res.text
    res = client.post("/api/v1/auth/login", json={
        "email": email, "password": password,
    })
    assert res.status_code == 200, res.text
    return {"Authorization": "Bearer " + res.json()["access_token"]}


def test_original_patient_fields_and_structured_visit_are_owner_scoped(monkeypatch):
    _test_db_only(monkeypatch)
    with TestClient(app) as client:
        a, b = _new_owner(client, "a"), _new_owner(client, "b")
        profile = {
            "neighborhood": "Quartier fictif",
            "address": "Adresse de test",
            "emergencyContactName": "Contact fictif",
            "emergencyContactPhone": "000000000",
            "currentMedications": "Traitement simulé",
            "surgicalHistory": "Non applicable",
            "familyHistory": "Historique fictif",
        }
        created = client.post("/api/v1/patients", headers=a, json={
            "display_name": "PATIENT FICTIF COMPLET",
            "age": 29, "sex": "F", "phone": "000000000",
            "profile": profile,
        })
        assert created.status_code == 201, created.text
        patient_id = created.json()["id"]
        assert created.json()["sex"] == "F"
        assert created.json()["profile"] == profile

        changed = client.put(f"/api/v1/patients/{patient_id}", headers=a,
                             json={
            "phone": "000000001",
            "allergies": "Aucune allergie fictive",
            "medical_history": "Antécédents fictifs",
            "profile": profile,
        })
        assert changed.status_code == 200, changed.text
        assert changed.json()["phone"] == "000000001"
        assert changed.json()["medical_history"] == "Antécédents fictifs"

        for path, body in [
            (f"/api/v1/patients/{patient_id}", {
                "phone": "", "allergies": "", "medical_history": "",
                "profile": {},
            }),
            (f"/api/v1/patients/{patient_id}/follow-up", {
                "to_review": True,
            }),
        ]:
            assert client.put(path, headers=b, json=body).status_code == 404

        flagged = client.put(f"/api/v1/patients/{patient_id}/follow-up",
                             headers=a, json={"to_review": True})
        assert flagged.status_code == 200
        assert flagged.json()["follow_up"] is True

        intake = {
            "schemaVersion": 1, "weightKg": 60.0,
            "symptomHistory": "Symptôme fictif",
            "careDisposition": "outpatient",
        }
        visit = client.post(f"/api/v1/patients/{patient_id}/visits",
                            headers=a, json={
            "reason": "Consultation fictive",
            "notes": "Données de test",
            "intake": intake,
        })
        assert visit.status_code == 201, visit.text
        assert visit.json()["intake"] == intake

        assert client.get(f"/api/v1/patients/{patient_id}",
                          headers=b).status_code == 404
        assert client.get(f"/api/v1/patients/{patient_id}/visits",
                          headers=b).status_code == 404

    with TestClient(app) as reopened:
        read = reopened.get(f"/api/v1/patients/{patient_id}", headers=a)
        assert read.status_code == 200
        assert read.json()["allergies"] == "Aucune allergie fictive"
        assert read.json()["profile"] == profile
        saved = reopened.get(f"/api/v1/patients/{patient_id}/visits",
                             headers=a)
        assert saved.status_code == 200
        assert saved.json()[0]["intake"] == intake
