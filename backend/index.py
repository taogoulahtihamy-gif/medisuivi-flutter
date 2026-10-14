"""Vercel Python entrypoint for the EXISTING MediSuivi FastAPI service.

The API and its JWT/owner checks stay in app.main. No alternate backend,
authentication flow, demo UI or database is created by this file.
"""
from app.main import app

__all__ = ["app"]
