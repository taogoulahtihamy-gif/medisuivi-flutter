"""Remote demo sandbox, on disposable CI PostgreSQL ONLY."""
from uuid import uuid4

from fastapi.testclient import TestClient
from sqlalchemy import text

from app.main import app, engine, settings


def test_remote_https_invite_and_synthetic_owner_isolation(monkeypatch):
    assert engine.dialect.name == "postgresql"
    assert engine.url.database == "medisuivi_ci"
    assert settings.environment == "sandbox"
    assert settings.email_auth_enabled is False
    assert settings.sandbox_registration_enabled
    assert settings.sandbox_writes_enabled
    assert len(settings.sandbox_invite_code) >= 32

    with engine.connect() as db:
        assert db.execute(text("SELECT version_num FROM alembic_version")).scalar_one() == "0006"

    def user(suffix):
        return {
            "email": f"demo-{suffix}-{uuid4().hex[:8]}@example.com",
            "first_name": "Compte", "last_name": f"Fictif {suffix}",
            "password": "Not-a-real-patient-credential-2026",
        }

    with TestClient(app) as client:
        allowed = client.options(
            "/api/v1/patients",
            headers={
                "Origin": settings.public_web_origin,
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "authorization",
            },
        )
        assert allowed.status_code == 200, allowed.text
        assert allowed.headers["access-control-allow-origin"] == settings.public_web_origin

        denied = client.options(
            "/api/v1/patients",
            headers={
                "Origin": "https://attacker.example.com",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "authorization",
            },
        )
        assert denied.status_code == 400
        assert denied.headers.get("access-control-allow-origin") is None

        a, b = user("a"), user("b")
        missing_invite = client.post("/api/v1/auth/register", json=a)
        assert missing_invite.status_code == 403

        wrong_invite = client.post("/api/v1/auth/register", json=a, headers={
            "X-MediSuivi-Sandbox-Invite": "not-the-invite",
        })
        assert wrong_invite.status_code == 403

        forbidden_email = user("wrong")
        forbidden_email["email"] = "a-real-account@example.com"
        response = client.post("/api/v1/auth/register", json=forbidden_email,
            headers={"X-MediSuivi-Sandbox-Invite": settings.sandbox_invite_code})
        assert response.status_code == 422

        for item in [a, b]:
            result = client.post("/api/v1/auth/register", json=item, headers={
                "X-MediSuivi-Sandbox-Invite": settings.sandbox_invite_code,
            })
            assert result.status_code == 201, result.text

        def login(item):
            result = client.post("/api/v1/auth/login", json={
                "email": item["email"], "password": item["password"],
            })
            assert result.status_code == 200, result.text
            return {"Authorization": "Bearer " + result.json()["access_token"]}

        auth_a, auth_b = login(a), login(b)

        not_synthetic = client.post("/api/v1/patients", headers=auth_a, json={
            "display_name": "VRAI PATIENT INTERDIT", "age": 29,
        })
        assert not_synthetic.status_code == 422

        patient = client.post("/api/v1/patients", headers=auth_a, json={
            "display_name": "PATIENT FICTIF P50 CI",
            "age": 29, "sex": "N",
        })
        assert patient.status_code == 201, patient.text
        patient_id = patient.json()["id"]

        assert client.get("/api/v1/patients", headers=auth_b).json() == []
        assert client.get(f"/api/v1/patients/{patient_id}",
                          headers=auth_b).status_code == 404

        followup = client.put(f"/api/v1/patients/{patient_id}/follow-up",
                              headers=auth_a, json={"to_review": True})
        assert followup.status_code == 200
        assert followup.json()["follow_up"] is True

        monkeypatch.setattr(settings, "sandbox_writes_enabled", False)
        assert client.post("/api/v1/patients", headers=auth_a, json={
            "display_name": "PATIENT FICTIF BLOQUÉ", "age": 28,
        }).status_code == 403

        monkeypatch.setattr(settings, "sandbox_registration_enabled", False)
        assert client.post("/api/v1/auth/register", json=user("c"), headers={
            "X-MediSuivi-Sandbox-Invite": settings.sandbox_invite_code,
        }).status_code == 403

        assert client.get("/ready").status_code == 200
