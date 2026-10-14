"""MediSuivi P1 foundation. Non-production until security/legal Go-No-Go.

Only synthetic patients in a controlled development environment.
All patient reads/writes are scoped to the JWT-authenticated practitioner.
No shared clinical credentials, no implicit team access, no PHI logging.
"""
from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel, ConfigDict, EmailStr, Field
from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, create_engine, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

ISSUER = "medisuivi-development"
AUDIENCE = "medisuivi-practitioners"
TOKEN_TTL_MINUTES = 15
bearer = HTTPBearer(auto_error=False)
hasher = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=2)


class Settings:
    def __init__(self) -> None:
        self.environment = os.environ.get("APP_ENV", "production").lower()
        self.database_url = os.environ.get("APP_DATABASE_URL", "")
        self.secret = os.environ.get("APP_JWT_SECRET", "")
        self.allow_registration = (
            os.environ.get("APP_ALLOW_DEVELOPMENT_REGISTRATION", "false").lower() == "true"
        )
        # This foundation explicitly REFUSES production traffic.
        if self.environment not in {"development", "test", "staging"}:
            raise RuntimeError("Prototype API: production prohibited until security approval")
        if not self.database_url:
            raise RuntimeError("APP_DATABASE_URL must be provided")
        if len(self.secret.encode("utf-8")) < 32 or self.secret.startswith("REPLACE_"):
            raise RuntimeError("APP_JWT_SECRET must be a unique random secret >=32 bytes")


settings = Settings()
engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "practitioners"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4()))
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(512), nullable=False)
    first_name: Mapped[str] = mapped_column(String(120), nullable=False)
    last_name: Mapped[str] = mapped_column(String(120), nullable=False)
    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    session_version: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    patients: Mapped[list[Patient]] = relationship(back_populates="practitioner")


class Patient(Base):
    __tablename__ = "patients"

    id: Mapped[str] = mapped_column(
        String(36), primary_key=True, default=lambda: str(uuid4()))
    owner_user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("practitioners.id", ondelete="RESTRICT"),
        nullable=False, index=True)
    display_name: Mapped[str] = mapped_column(String(180), nullable=False)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    practitioner: Mapped[User] = relationship(back_populates="patients")


def get_db():
    with SessionLocal() as session:
        yield session


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class RegisterIn(StrictModel):
    email: EmailStr
    password: str = Field(min_length=12, max_length=128)
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)


class LoginIn(StrictModel):
    email: EmailStr
    password: str


class MeOut(StrictModel):
    id: str
    email: EmailStr
    first_name: str
    last_name: str


class TokenOut(StrictModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = TOKEN_TTL_MINUTES * 60


class PatientIn(StrictModel):
    display_name: str = Field(min_length=1, max_length=180)
    age: int = Field(ge=0, le=125)


class PatientOut(PatientIn):
    id: str


def invalid_token() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Session invalide ou expirée",
        headers={"WWW-Authenticate": "Bearer"},
    )


def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise invalid_token()
    try:
        claims = jwt.decode(
            credentials.credentials, settings.secret,
            algorithms=["HS256"], audience=AUDIENCE, issuer=ISSUER,
            options={"require": ["sub", "sv", "exp", "iat", "jti", "aud", "iss"]},
            leeway=0)
        user_id = claims["sub"]
        version = claims["sv"]
        if not isinstance(user_id, str) or not isinstance(version, int):
            raise invalid_token()
    except (jwt.PyJWTError, TypeError, ValueError, KeyError) as exc:
        raise invalid_token() from exc

    user = db.get(User, user_id)
    if user is None or not user.active or user.session_version != version:
        raise invalid_token()
    return user


def issue_token(user: User) -> TokenOut:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user.id,
        "sv": user.session_version,
        "iss": ISSUER, "aud": AUDIENCE,
        "jti": str(uuid4()),
        "iat": now, "exp": now + timedelta(minutes=TOKEN_TTL_MINUTES),
    }
    return TokenOut(access_token=jwt.encode(payload, settings.secret, algorithm="HS256"))


def api_app() -> FastAPI:
    app = FastAPI(
        title="MediSuivi API (development only)",
        version="0.1.0-dev",
        docs_url="/docs" if settings.environment == "development" else None,
        redoc_url=None,
    )

    @app.get("/health")
    def health():
        return {"status": "ok", "environment": "non-production"}

    @app.get("/ready")
    def ready(db: Session = Depends(get_db)):
        try:
            db.execute(text("SELECT 1"))
        except Exception as exc:
            raise HTTPException(status_code=503, detail="Base indisponible") from exc
        return {"ready": True}

    @app.post("/api/v1/auth/register", response_model=MeOut, status_code=201)
    def register(data: RegisterIn, db: Session = Depends(get_db)):
        if settings.environment != "development" or not settings.allow_registration:
            raise HTTPException(status_code=403, detail="Inscription indisponible")
        normalized = str(data.email).strip().lower()
        user = User(
            email=normalized, password_hash=hasher.hash(data.password),
            first_name=data.first_name.strip(), last_name=data.last_name.strip(),
        )
        if not user.first_name or not user.last_name:
            raise HTTPException(status_code=422, detail="Nom et prénom obligatoires")
        db.add(user)
        try:
            db.commit()
        except IntegrityError as exc:
            db.rollback()
            raise HTTPException(status_code=409, detail="Compte déjà existant") from exc
        db.refresh(user)
        return MeOut.model_validate(user, from_attributes=True)

    @app.post("/api/v1/auth/login", response_model=TokenOut)
    def login(data: LoginIn, db: Session = Depends(get_db)):
        normalized = str(data.email).strip().lower()
        user = db.scalar(select(User).where(User.email == normalized))
        # Keep failure messages generic. Public deployment requires real
        # rate limiting, email verification and a security review.
        if user is None or not user.active:
            raise HTTPException(status_code=401, detail="Identifiants invalides")
        try:
            hasher.verify(user.password_hash, data.password)
        except (VerificationError, ValueError) as exc:
            raise HTTPException(
                status_code=401, detail="Identifiants invalides") from exc
        return issue_token(user)

    @app.get("/api/v1/me", response_model=MeOut)
    def me(user: User = Depends(current_user)):
        return MeOut.model_validate(user, from_attributes=True)

    @app.post("/api/v1/auth/logout", status_code=204)
    def logout(user: User = Depends(current_user), db: Session = Depends(get_db)):
        # Revokes ALL tokens issued before this call for this user.
        user.session_version += 1
        db.add(user)
        db.commit()

    @app.get("/api/v1/patients", response_model=list[PatientOut])
    def list_patients(user: User = Depends(current_user), db: Session = Depends(get_db)):
        rows = db.scalars(
            select(Patient).where(Patient.owner_user_id == user.id)
            .order_by(Patient.created_at.desc())).all()
        return [PatientOut.model_validate(p, from_attributes=True) for p in rows]

    @app.post("/api/v1/patients", response_model=PatientOut, status_code=201)
    def create_patient(data: PatientIn, user: User = Depends(current_user),
                       db: Session = Depends(get_db)):
        # All clinical writes are deliberately restricted to development.
        if settings.environment != "development":
            raise HTTPException(status_code=403, detail="Saisie clinique désactivée")
        patient = Patient(
            owner_user_id=user.id, display_name=data.display_name.strip(), age=data.age)
        if not patient.display_name:
            raise HTTPException(status_code=422, detail="Nom du patient obligatoire")
        db.add(patient)
        db.commit()
        db.refresh(patient)
        return PatientOut.model_validate(patient, from_attributes=True)

    @app.get("/api/v1/patients/{patient_id}", response_model=PatientOut)
    def get_patient(patient_id: str, user: User = Depends(current_user),
                    db: Session = Depends(get_db)):
        # Identical 404 for missing / other-user patient (no enumeration).
        patient = db.scalar(select(Patient).where(
            Patient.id == patient_id, Patient.owner_user_id == user.id))
        if patient is None:
            raise HTTPException(status_code=404, detail="Dossier introuvable")
        return PatientOut.model_validate(patient, from_attributes=True)

    return app


app = api_app()
