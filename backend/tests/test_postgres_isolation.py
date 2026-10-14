"""PostgreSQL-only security & migration smoke tests with synthetic accounts.

Execute in a fresh CI Postgres service after 'alembic upgrade head'.
DO NOT import test_auth_isolation here; it sets up a separate SQLite engine.
"""
from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import inspect, select, text
from sqlalchemy.exc import IntegrityError

from app.main import (
    FollowUp, LabExam, Patient, SessionLocal, User, Visit, app, engine,
    settings,
)


@pytest.fixture(scope="module", autouse=True)
def validate_postgres_migrations():
    assert engine.dialect.name == "postgresql"
    with engine.connect() as connection:
        assert connection.execute(text("SELECT version_num FROM alembic_version")).scalar() == "0002"
    tables = set(inspect(engine).get_table_names())
    assert {"patients", "practitioners", "visits", "exams", "followups"} <= tables
    settings.environment = "development"
    settings.allow_registration = True
    yield


def test_composite_ownership_in_real_postgresql():
    with TestClient(app) as client:
        for email in ["alpha@medisuvi-ci.org", "beta@medisuvi-ci.org"]:
            result = client.post("/api/v1/auth/register", json={
                "email": email, "password": "test-long-random-password-123",
                "first_name": "Médecin", "last_name": "Synthétique",
            })
            assert result.status_code == 201, result.text

        tokens = {}
        for label in ["alpha", "beta"]:
            result = client.post("/api/v1/auth/login", json={
                "email": f"{label}@medisuvi-ci.org",
                "password": "test-long-random-password-123",
            })
            assert result.status_code == 200
            tokens[label] = {"Authorization": f"Bearer {result.json()['access_token']}"}

        a, b = tokens["alpha"], tokens["beta"]
        p = client.post("/api/v1/patients", headers=a,
                        json={"display_name": "PATIENT FICTIF CI", "age": 24})
        assert p.status_code == 201, p.text
        patient_id = p.json()["id"]

        for resource, payload in [
            ("visits", {"reason": "Examen fictif"}),
            ("exams", {"title": "Examen biologique fictif"}),
            ("followups", {"scheduled_at": datetime.now(timezone.utc).isoformat(),
                           "reason": "Suivi fictif"}),
        ]:
            uri = f"/api/v1/patients/{patient_id}/{resource}"
            assert client.post(uri, headers=b, json=payload).status_code == 404
            own = client.post(uri, headers=a, json=payload)
            assert own.status_code == 201, own.text
            assert len(client.get(uri, headers=a).json()) == 1
            assert client.get(uri, headers=b).status_code == 404

        with SessionLocal() as db:
            user_a = db.scalar(select(User).where(User.email == "alpha@medisuvi-ci.org"))
            user_b = db.scalar(select(User).where(User.email == "beta@medisuvi-ci.org"))
            assert user_a.id != user_b.id
            for entry in [
                Visit(patient_id=patient_id, owner_user_id=user_b.id, reason="Injection"),
                LabExam(patient_id=patient_id, owner_user_id=user_b.id,
                        title="Injection"),
                FollowUp(patient_id=patient_id, owner_user_id=user_b.id,
                         reason="Injection", scheduled_at=datetime.now(timezone.utc)),
            ]:
                db.add(entry)
                with pytest.raises(IntegrityError):
                    db.flush()
                db.rollback()

        exam = client.get(f"/api/v1/patients/{patient_id}/exams",
                          headers=a).json()[0]["id"]
        assert client.put(f"/api/v1/exams/{exam}/result", headers=b,
                          json={"result": "Cross-owner write"}).status_code == 404
        assert client.put(f"/api/v1/exams/{exam}/result", headers=a,
                          json={"result": "Test normal"}).status_code == 200

        followup = client.get(f"/api/v1/patients/{patient_id}/followups",
                              headers=a).json()[0]["id"]
        assert client.put(f"/api/v1/followups/{followup}/close", headers=b,
                          json={"completed": True}).status_code == 404
        assert client.put(f"/api/v1/followups/{followup}/close", headers=a,
                          json={"completed": True}).status_code == 200

        assert client.post("/api/v1/auth/logout", headers=a).status_code == 204
        assert client.get(f"/api/v1/patients/{patient_id}/visits",
                          headers=a).status_code == 401
