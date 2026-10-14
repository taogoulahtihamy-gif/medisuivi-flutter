"""Test profile ownership, avatar validation, privacy, and image hygiene."""
from io import BytesIO

from PIL import Image
from test_auth_isolation import client, fresh_database, login, register  # noqa: F401


def webp_payload() -> bytes:
    output = BytesIO()
    Image.new("RGB", (480, 600), (30, 75, 68)).save(output, format="PNG")
    return output.getvalue()


def test_profiles_and_avatars_are_account_scoped(client):
    a = register(client, "photo-alpha@medisuvi-ci.org")
    b = register(client, "photo-beta@medisuvi-ci.org")
    ta = login(client, a["email"])
    tb = login(client, b["email"])
    assert client.get("/api/v1/me", headers=ta).json()["has_avatar"] is False
    assert client.get("/api/v1/me/avatar", headers=tb).status_code == 404
    payload = webp_payload()

    response = client.put("/api/v1/me/avatar", headers={
        **ta, "Content-Type": "image/png"}, content=payload)
    assert response.status_code == 200, response.text
    assert response.json()["has_avatar"] is True
    assert "avatar_webp" not in response.json()
    owner_avatar = client.get("/api/v1/me/avatar", headers=ta)
    assert owner_avatar.status_code == 200
    assert owner_avatar.headers["content-type"].startswith("image/webp")
    assert owner_avatar.headers["cache-control"].startswith("no-store")
    with Image.open(BytesIO(owner_avatar.content)) as img:
        assert img.format == "WEBP"
        assert img.size == (410, 512)
        assert not img.getexif()
    assert client.get("/api/v1/me/avatar", headers=tb).status_code == 404

    updated = client.put("/api/v1/me", headers=ta, json={
        "first_name": "Awa", "last_name": "Essai", "phone": "+221701234567",
        "specialty": "Médecine générale"
    })
    assert updated.status_code == 200, updated.text
    assert updated.json()["specialty"] == "Médecine générale"
    assert client.get("/api/v1/me", headers=tb).json()["first_name"] == "Médecin"
    assert client.get("/api/v1/me", headers=ta).json()["phone"] == "+221701234567"

    assert client.delete("/api/v1/me/avatar", headers=tb).status_code == 204
    assert client.get("/api/v1/me/avatar", headers=ta).status_code == 200
    assert client.delete("/api/v1/me/avatar", headers=ta).status_code == 204
    assert client.get("/api/v1/me/avatar", headers=ta).status_code == 404


def test_avatar_fails_closed_and_profile_ignores_owner_forgery(client):
    register(client, "test-image@medisuvi-ci.org")
    bearer = login(client, "test-image@medisuvi-ci.org")
    assert client.put("/api/v1/me/avatar", headers={
        **bearer, "Content-Type": "image/svg+xml"}, content=b"<svg/>").status_code == 415
    assert client.put("/api/v1/me/avatar", headers={
        **bearer, "Content-Type": "image/png"}, content=b"not-png").status_code == 422
    assert client.put("/api/v1/me/avatar", headers={
        **bearer, "Content-Type": "image/png"}, content=b"X" * 2_100_000).status_code == 413
    assert client.put("/api/v1/me", headers=bearer, json={
        "first_name": "Dr", "last_name": "Fictif", "phone": "", "specialty": "",
        "owner_user_id": "forged"}).status_code == 422
    assert client.put("/api/v1/me", headers=bearer, json={
        "first_name": " ", "last_name": "Fictif",
        "phone": "", "specialty": ""}).status_code == 422
    assert client.get("/api/v1/me/avatar").status_code == 401
    assert client.delete("/api/v1/me/avatar").status_code == 401


def test_staging_disables_profile_and_avatar_writes(client, monkeypatch):
    from app.main import settings
    register(client, "locked@medisuvi-ci.org")
    bearer = login(client, "locked@medisuvi-ci.org")
    monkeypatch.setattr(settings, "environment", "staging")
    assert client.put("/api/v1/me", headers=bearer, json={
        "first_name":"A", "last_name":"B"}).status_code == 403
    assert client.put("/api/v1/me/avatar", headers={
        **bearer, "Content-Type": "image/png"}, content=webp_payload()).status_code == 403
    assert client.delete("/api/v1/me/avatar", headers=bearer).status_code == 403
