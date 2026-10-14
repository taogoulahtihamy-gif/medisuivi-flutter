"""MediSuivi P1 foundation. Non-production until security/legal Go-No-Go.

Only synthetic patients in a controlled development environment.
All patient reads/writes are scoped to the JWT-authenticated practitioner.
No shared clinical credentials, no implicit team access, no PHI logging.
"""
from __future__ import annotations

import os
import hashlib
import hmac
import math
import secrets
from io import BytesIO
from datetime import datetime, timedelta, timezone
from typing import Literal
from uuid import uuid4

import jwt
from PIL import Image, UnidentifiedImageError
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError
from fastapi import Depends, FastAPI, HTTPException, Request, Response, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy import (
    Boolean, CheckConstraint, DateTime, Float, ForeignKey, ForeignKeyConstraint,
    Integer, LargeBinary, String, Text, UniqueConstraint, create_engine, event, select, text,
)
from sqlalchemy.dialects.postgresql import insert as postgresql_insert
from sqlalchemy.dialects.sqlite import insert as sqlite_insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker

ISSUER = "medisuivi-development"
AUDIENCE = "medisuivi-practitioners"
TOKEN_TTL_MINUTES = 15
LOGIN_FAILURE_LIMIT = 5
LOGIN_WINDOW = timedelta(minutes=15)
LOGIN_LOCKOUT = timedelta(minutes=15)
bearer = HTTPBearer(auto_error=False)
hasher = PasswordHasher(time_cost=3, memory_cost=65536, parallelism=2)
# A genuine Argon2id verification also occurs for unregistered addresses.
# This cannot replace external IP/risk-based rate limiting in production.
_FAKE_PASSWORD_HASH = hasher.hash('nonexistent-synthetic-practitioner') 


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
if settings.database_url.startswith('sqlite'):
    # SQLite integration tests must enforce the same FK invariants as PostgreSQL.
    @event.listens_for(engine, 'connect')
    def enable_sqlite_fk(connection, _):
        cursor = connection.cursor()
        cursor.execute('PRAGMA foreign_keys=ON')
        cursor.close()
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
    phone: Mapped[str] = mapped_column(String(25), nullable=False, default="")
    specialty: Mapped[str] = mapped_column(String(120), nullable=False, default="")
    avatar_webp: Mapped[bytes | None] = mapped_column(LargeBinary, nullable=True)

    @property
    def has_avatar(self) -> bool:
        return self.avatar_webp is not None

    active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    session_version: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    patients: Mapped[list[Patient]] = relationship(back_populates="practitioner")


class AuthSession(Base):
    """A distinct revocable session for each sign-in (not shared across users)."""
    __tablename__ = "auth_sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey(
        "practitioners.id", ondelete="RESTRICT"), nullable=False, index=True)
    session_version: Mapped[int] = mapped_column(Integer, nullable=False)
    refresh_digest: Mapped[str] = mapped_column(String(64), nullable=False)
    previous_digest: Mapped[str | None] = mapped_column(String(64))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class LoginAttempt(Base):
    """Pseudonymous login counter. Email, IP, password never persisted here."""

    __tablename__ = "login_attempts"
    __table_args__ = (
        CheckConstraint("failed_count >= 0", name="ck_login_failed_count_positive"),
    )

    key: Mapped[str] = mapped_column(String(64), primary_key=True)
    failed_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    window_started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False)
    blocked_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True)


class Patient(Base):
    __tablename__ = "patients"
    __table_args__ = (UniqueConstraint("id", "owner_user_id", name="uq_patient_id_owner"),)

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


class ClinicalChild(Base):
    """Abstract shared parent. Both owner and patient are constrained in the DB.

    A child row cannot point to a patient owned by another practitioner even
    if an application-level ownership check were ever omitted.
    """
    __abstract__ = True

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid4()))
    owner_user_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("practitioners.id", ondelete="RESTRICT"),
        nullable=False, index=True)
    patient_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))


class Visit(ClinicalChild):
    __tablename__ = "visits"
    __table_args__ = (
        ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_visits_patient_owner"),
    )

    reason: Mapped[str] = mapped_column(String(500), nullable=False)
    temperature: Mapped[float | None] = mapped_column(Float)
    systolic: Mapped[int | None] = mapped_column(Integer)
    diastolic: Mapped[int | None] = mapped_column(Integer)
    pulse: Mapped[int | None] = mapped_column(Integer)
    spo2: Mapped[int | None] = mapped_column(Integer)
    notes: Mapped[str] = mapped_column(Text, nullable=False, default="")


class LabExam(ClinicalChild):
    __tablename__ = "exams"
    __table_args__ = (
        ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_exams_patient_owner"),
        CheckConstraint("status IN ('pending','complete')", name="ck_exam_status"),
    )

    title: Mapped[str] = mapped_column(String(300), nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="pending")
    result: Mapped[str | None] = mapped_column(Text)
    result_recorded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class FollowUp(ClinicalChild):
    __tablename__ = "followups"
    __table_args__ = (
        ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_followups_patient_owner"),
        CheckConstraint("status IN ('planned','completed','cancelled')",
                        name="ck_followup_status"),
    )

    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    reason: Mapped[str] = mapped_column(String(500), nullable=False)
    notes: Mapped[str] = mapped_column(Text, nullable=False, default="")
    status: Mapped[str] = mapped_column(String(16), nullable=False, default="planned")
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


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


class ChangePasswordIn(StrictModel):
    current_password: str = Field(min_length=1, max_length=128)
    new_password: str = Field(min_length=12, max_length=128)


class MeOut(StrictModel):
    id: str
    email: EmailStr
    first_name: str
    last_name: str
    phone: str
    specialty: str
    has_avatar: bool


class UpdateProfileIn(StrictModel):
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)
    phone: str = Field(default="", max_length=25)
    specialty: str = Field(default="", max_length=120)


class TokenOut(StrictModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = TOKEN_TTL_MINUTES * 60


class RefreshIn(StrictModel):
    refresh_token: str = Field(min_length=60, max_length=200)


class PatientIn(StrictModel):
    display_name: str = Field(min_length=1, max_length=180)
    age: int = Field(ge=0, le=125)


class PatientOut(PatientIn):
    id: str


class VisitIn(StrictModel):
    reason: str = Field(min_length=1, max_length=500)
    temperature: float | None = Field(default=None, ge=25, le=45)
    systolic: int | None = Field(default=None, ge=40, le=280)
    diastolic: int | None = Field(default=None, ge=20, le=180)
    pulse: int | None = Field(default=None, ge=20, le=250)
    spo2: int | None = Field(default=None, ge=50, le=100)
    notes: str = Field(default="", max_length=4000)


class VisitOut(VisitIn):
    id: str
    patient_id: str
    created_at: datetime


class ExamIn(StrictModel):
    title: str = Field(min_length=1, max_length=300)


class ExamOut(ExamIn):
    id: str
    patient_id: str
    status: Literal["pending", "complete"]
    result: str | None
    result_recorded_at: datetime | None
    created_at: datetime


class ExamResultIn(StrictModel):
    result: str = Field(min_length=1, max_length=10000)


class FollowUpIn(StrictModel):
    scheduled_at: datetime
    reason: str = Field(min_length=1, max_length=500)
    notes: str = Field(default="", max_length=4000)

    @field_validator("scheduled_at")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("Date avec fuseau horaire obligatoire")
        return value.astimezone(timezone.utc)


class FollowUpOut(FollowUpIn):
    # SQLite test runner drops timezone metadata; input validation still
    # REQUIRES a timezone, but persisted UTC timestamps are restored on read.
    @field_validator("scheduled_at", mode="before")
    @classmethod
    def persisted_utc(cls, value):
        if isinstance(value, datetime) and value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value

    id: str
    patient_id: str
    status: Literal["planned", "completed", "cancelled"]
    completed_at: datetime | None
    created_at: datetime


class CloseFollowUpIn(StrictModel):
    completed: bool


def owned_patient(db: Session, user: User, patient_id: str) -> Patient:
    patient = db.scalar(
        select(Patient).where(Patient.id == patient_id,
                              Patient.owner_user_id == user.id))
    if patient is None:
        # A foreign practitioner's identifier is indistinguishable from missing.
        raise HTTPException(status_code=404, detail="Dossier introuvable")
    return patient


def dev_write_only() -> None:
    if settings.environment != "development":
        raise HTTPException(status_code=403, detail="Saisie clinique désactivée")


def clean_text(value: str) -> str:
    result = value.strip()
    if not result:
        raise HTTPException(status_code=422, detail="Champ vide")
    return result


def invalid_token() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Session invalide ou expirée",
        headers={"WWW-Authenticate": "Bearer"},
    )


def utc(value: datetime) -> datetime:
    # SQLite tests store UTC naive datetimes; PostgreSQL stores tz-aware.
    return value.replace(tzinfo=timezone.utc) if value.tzinfo is None else (
        value.astimezone(timezone.utc))


def authenticated_principal(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> tuple[User, AuthSession]:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise invalid_token()
    try:
        claims = jwt.decode(
            credentials.credentials, settings.secret,
            algorithms=["HS256"], audience=AUDIENCE, issuer=ISSUER,
            options={"require": ["sub", "sv", "sid", "exp", "iat", "jti", "aud", "iss"]},
            leeway=0)
        user_id = claims["sub"]
        version = claims["sv"]
        session_id = claims["sid"]
        if (not isinstance(user_id, str) or not isinstance(version, int)
                or not isinstance(session_id, str)):
            raise invalid_token()
    except (jwt.PyJWTError, TypeError, ValueError, KeyError) as exc:
        raise invalid_token() from exc

    user = db.get(User, user_id)
    session = db.get(AuthSession, session_id)
    if (user is None or not user.active or user.session_version != version
            or session is None or session.user_id != user_id
            or session.session_version != version or session.revoked_at is not None
            or utc(session.expires_at) <= datetime.now(timezone.utc)):
        raise invalid_token()
    return (user, session)


def current_user(
    principal: tuple[User, AuthSession] = Depends(authenticated_principal),
) -> User:
    return principal[0]


def current_session(
    principal: tuple[User, AuthSession] = Depends(authenticated_principal),
) -> AuthSession:
    return principal[1]


def _login_key(normalized_email: str) -> str:
    # HMAC key hides email identity even if the rate-limit table is disclosed.
    return hmac.new(settings.secret.encode("utf-8"),
                    ("login-guard:v1:" + normalized_email).encode("utf-8"),
                    hashlib.sha256).hexdigest()


def login_attempt_row(db: Session, normalized_email: str,
                      now: datetime) -> LoginAttempt:
    """Atomically get a keyed row and hold an account-scoped DB row lock.

    PostgreSQL serializes concurrent attempts for the same email. SQLite
    supports the conflict insert for lightweight synthetic CI testing.
    """
    key = _login_key(normalized_email)
    payload = dict(key=key, failed_count=0, window_started_at=now)
    dialect = db.get_bind().dialect.name
    if dialect == "postgresql":
        insert_statement = postgresql_insert(LoginAttempt)
    elif dialect == "sqlite":
        insert_statement = sqlite_insert(LoginAttempt)
    else:
        raise RuntimeError("Unsupported authentication storage dialect")
    db.execute(insert_statement.values(**payload).on_conflict_do_nothing(
        index_elements=["key"]))
    row = db.scalar(select(LoginAttempt).where(
        LoginAttempt.key == key).with_for_update())
    if row is None:
        raise RuntimeError("Unable to obtain login attempt lock")
    active_lock = row.blocked_until is not None and utc(row.blocked_until) > now
    # Do not reset an active 15-minute lock just because the original
    # failure-counting window has expired.
    if not active_lock and (row.blocked_until is not None or
                            utc(row.window_started_at) + LOGIN_WINDOW <= now):
        row.failed_count = 0
        row.window_started_at = now
        row.blocked_until = None
    return row


def throttled_login(blocked_until: datetime, now: datetime) -> HTTPException:
    wait_seconds = max(1, math.ceil((utc(blocked_until) - now).total_seconds()))
    # The same response is used for existing and nonexistent accounts.
    return HTTPException(
        status_code=429, detail="Trop de tentatives. Réessayez plus tard.",
        headers={"Retry-After": str(wait_seconds)},
    )


def _digest_refresh(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _mint_refresh(session_id: str) -> str:
    return f"{session_id}.{secrets.token_urlsafe(48)}"


def issue_token(user: User, session_id: str, refresh_token: str) -> TokenOut:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user.id, "sid": session_id,
        "sv": user.session_version,
        "iss": ISSUER, "aud": AUDIENCE,
        "jti": str(uuid4()),
        "iat": now, "exp": now + timedelta(minutes=TOKEN_TTL_MINUTES),
    }
    return TokenOut(
        access_token=jwt.encode(payload, settings.secret, algorithm="HS256"),
        refresh_token=refresh_token,
    )


def open_session(user: User, db: Session) -> TokenOut:
    now = datetime.now(timezone.utc)
    sid = str(uuid4())
    raw = _mint_refresh(sid)
    row = AuthSession(
        id=sid, user_id=user.id, session_version=user.session_version,
        refresh_digest=_digest_refresh(raw),
        created_at=now, expires_at=now + timedelta(days=7),
    )
    db.add(row)
    db.commit()
    return issue_token(user, sid, raw)


def api_app() -> FastAPI:
    app = FastAPI(
        title="MediSuivi API (development only)",
        version="0.1.0-dev",
        docs_url="/docs" if settings.environment == "development" else None,
        redoc_url=None,
    )

    # Exact loopback origins for the Flutter Web app hosted on the developer
    # laptop. HTTPS staging is read-only and does not accept public signups.
    # Android native applications are not subject to browser CORS.
    if settings.environment in {"development", "staging"}:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=["http://127.0.0.1:8080", "http://localhost:8080"],
            allow_credentials=False,
            allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            allow_headers=["Authorization", "Content-Type"],
            max_age=600,
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
        now = datetime.now(timezone.utc)
        attempt = login_attempt_row(db, normalized, now)
        if attempt.blocked_until is not None and utc(attempt.blocked_until) > now:
            raise throttled_login(attempt.blocked_until, now)
        user = db.scalar(select(User).where(User.email == normalized))
        candidate_hash = (user.password_hash if user is not None and user.active
                          else _FAKE_PASSWORD_HASH)
        try:
            verified = bool(hasher.verify(candidate_hash, data.password))
        except (VerificationError, ValueError):
            verified = False
        if verified and user is not None and user.active:
            attempt.failed_count = 0
            attempt.blocked_until = None
            attempt.window_started_at = now
            # open_session commits the reset and session in the same transaction.
            return open_session(user, db)

        attempt.failed_count += 1
        if attempt.failed_count >= LOGIN_FAILURE_LIMIT:
            attempt.blocked_until = now + LOGIN_LOCKOUT
        db.commit()
        if attempt.blocked_until is not None:
            raise throttled_login(attempt.blocked_until, now)
        # Explicitly identical for known and nonexistent emails.
        raise HTTPException(status_code=401, detail="Identifiants invalides")

    @app.get("/api/v1/me", response_model=MeOut)
    def me(user: User = Depends(current_user)):
        return MeOut.model_validate(user, from_attributes=True)

    @app.put("/api/v1/me", response_model=MeOut)
    def update_profile(data: UpdateProfileIn, user: User = Depends(current_user),
                       db: Session = Depends(get_db)):
        dev_write_only()
        user.first_name = clean_text(data.first_name)
        user.last_name = clean_text(data.last_name)
        user.phone = data.phone.strip()
        user.specialty = data.specialty.strip()
        db.commit()
        db.refresh(user)
        return MeOut.model_validate(user, from_attributes=True)

    @app.put("/api/v1/me/password", status_code=204)
    def change_my_password(data: ChangePasswordIn,
                           user: User = Depends(current_user),
                           db: Session = Depends(get_db)):
        """Authenticated password change revokes ALL practitioner sessions.

        Password recovery by email is intentionally not implemented here:
        there is not yet an approved email-delivery/verification provider.
        """
        dev_write_only()
        now = datetime.now(timezone.utc)
        attempt = login_attempt_row(db, user.email, now)
        if attempt.blocked_until is not None and utc(attempt.blocked_until) > now:
            raise throttled_login(attempt.blocked_until, now)
        try:
            valid_current = bool(hasher.verify(
                user.password_hash, data.current_password))
        except (VerificationError, ValueError):
            valid_current = False
        if not valid_current:
            attempt.failed_count += 1
            if attempt.failed_count >= LOGIN_FAILURE_LIMIT:
                attempt.blocked_until = now + LOGIN_LOCKOUT
            db.commit()
            if attempt.blocked_until is not None:
                raise throttled_login(attempt.blocked_until, now)
            raise HTTPException(status_code=400,
                                detail="Mot de passe actuel incorrect")
        if hmac.compare_digest(
                data.current_password.encode("utf-8"),
                data.new_password.encode("utf-8")):
            raise HTTPException(status_code=422,
                                detail="Choisissez un nouveau mot de passe différent")
        user.password_hash = hasher.hash(data.new_password)
        user.session_version += 1
        attempt.failed_count = 0
        attempt.blocked_until = None
        attempt.window_started_at = now
        db.commit()
        # All previously issued JWT access/refresh credentials are rejected.

    @app.get("/api/v1/me/avatar")
    def get_my_avatar(user: User = Depends(current_user)):
        if user.avatar_webp is None:
            raise HTTPException(status_code=404, detail="Photo introuvable")
        return Response(content=user.avatar_webp, media_type="image/webp",
                        headers={"Cache-Control": "no-store, private",
                                 "X-Content-Type-Options": "nosniff"})

    @app.put("/api/v1/me/avatar", response_model=MeOut)
    async def upload_my_avatar(request: Request, user: User = Depends(current_user),
                               db: Session = Depends(get_db)):
        dev_write_only()
        supported = {"image/jpeg", "image/png", "image/webp"}
        if request.headers.get("content-type", "").split(";")[0].lower() not in supported:
            raise HTTPException(status_code=415, detail="Format de photo invalide")
        # Stream with early cutoff, so a malicious upload cannot be arbitrarily large.
        payload = bytearray()
        async for chunk in request.stream():
            payload.extend(chunk)
            if len(payload) > 2 * 1024 * 1024:
                raise HTTPException(status_code=413, detail="Photo trop volumineuse")
        if not payload:
            raise HTTPException(status_code=422, detail="Photo vide")
        try:
            with Image.open(BytesIO(payload)) as original:
                if original.format not in {"JPEG", "PNG", "WEBP"}:
                    raise ValueError("Unsupported image")
                if original.width < 32 or original.height < 32:
                    raise ValueError("Image dimensions invalid")
                if original.width * original.height > 4_000_000:
                    raise ValueError("Too many pixels")
                original.verify()
            with Image.open(BytesIO(payload)) as original:
                picture = original.convert("RGB")
                picture.thumbnail((512, 512), Image.Resampling.LANCZOS)
                output = BytesIO()
                picture.save(output, format="WEBP", quality=82, method=5)
                safe_webp = output.getvalue()  # Re-encoding strips EXIF/metadata.
        except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError) as exc:
            raise HTTPException(status_code=422, detail="Image illisible") from exc
        if len(safe_webp) > 500_000:
            raise HTTPException(status_code=413, detail="Photo trop volumineuse")
        user.avatar_webp = safe_webp
        db.commit()
        db.refresh(user)
        return MeOut.model_validate(user, from_attributes=True)

    @app.delete("/api/v1/me/avatar", status_code=204)
    def delete_my_avatar(user: User = Depends(current_user),
                         db: Session = Depends(get_db)):
        dev_write_only()
        user.avatar_webp = None
        db.commit()

    @app.post("/api/v1/auth/refresh", response_model=TokenOut)
    def refresh(data: RefreshIn, db: Session = Depends(get_db)):
        # PostgreSQL SELECT FOR UPDATE prevents simultaneous rotation races.
        sid = data.refresh_token.split(".", 1)[0]
        row = db.scalar(select(AuthSession).where(
            AuthSession.id == sid).with_for_update())
        if row is None or row.revoked_at is not None:
            raise invalid_token()
        now = datetime.now(timezone.utc)
        user = db.get(User, row.user_id)
        if (user is None or not user.active or
                row.session_version != user.session_version or
                utc(row.expires_at) <= now):
            raise invalid_token()

        provided_digest = _digest_refresh(data.refresh_token)
        if not hmac.compare_digest(row.refresh_digest, provided_digest):
            if (row.previous_digest is not None and
                    hmac.compare_digest(row.previous_digest, provided_digest)):
                # Confirmed reuse of the last rotated credential revokes
                # this device's session, without affecting other devices.
                row.revoked_at = now
                db.commit()
            raise invalid_token()

        raw = _mint_refresh(row.id)
        row.previous_digest = row.refresh_digest
        row.refresh_digest = _digest_refresh(raw)
        db.commit()
        return issue_token(user, row.id, raw)

    @app.post("/api/v1/auth/logout", status_code=204)
    def logout(session: AuthSession = Depends(current_session),
               db: Session = Depends(get_db)):
        # Only the current device is revoked.
        session.revoked_at = datetime.now(timezone.utc)
        db.commit()

    @app.post("/api/v1/auth/logout-all", status_code=204)
    def logout_all(user: User = Depends(current_user),
                   db: Session = Depends(get_db)):
        # Changing the version also invalidates all outstanding refresh tokens.
        user.session_version += 1
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

    # P2: all clinical operations are nested under an OWNED patient, or
    # select by ID + owner for updates. Caller-supplied owner is forbidden.
    @app.get("/api/v1/patients/{patient_id}/visits", response_model=list[VisitOut])
    def list_visits(patient_id: str, user: User = Depends(current_user),
                    db: Session = Depends(get_db)):
        owned_patient(db, user, patient_id)
        records = db.scalars(select(Visit).where(
            Visit.patient_id == patient_id, Visit.owner_user_id == user.id)
            .order_by(Visit.created_at.desc())).all()
        return [VisitOut.model_validate(item, from_attributes=True) for item in records]

    @app.post("/api/v1/patients/{patient_id}/visits",
              response_model=VisitOut, status_code=201)
    def create_visit(patient_id: str, data: VisitIn,
                     user: User = Depends(current_user), db: Session = Depends(get_db)):
        dev_write_only()
        owned_patient(db, user, patient_id)
        row = Visit(patient_id=patient_id, owner_user_id=user.id,
                    **(data.model_dump() | {"reason": clean_text(data.reason)}))
        db.add(row)
        db.commit()
        db.refresh(row)
        return VisitOut.model_validate(row, from_attributes=True)

    @app.get("/api/v1/patients/{patient_id}/exams", response_model=list[ExamOut])
    def list_exams(patient_id: str, user: User = Depends(current_user),
                   db: Session = Depends(get_db)):
        owned_patient(db, user, patient_id)
        records = db.scalars(select(LabExam).where(
            LabExam.patient_id == patient_id, LabExam.owner_user_id == user.id)
            .order_by(LabExam.created_at.desc())).all()
        return [ExamOut.model_validate(item, from_attributes=True) for item in records]

    @app.post("/api/v1/patients/{patient_id}/exams",
              response_model=ExamOut, status_code=201)
    def create_exam(patient_id: str, data: ExamIn,
                    user: User = Depends(current_user), db: Session = Depends(get_db)):
        dev_write_only()
        owned_patient(db, user, patient_id)
        row = LabExam(patient_id=patient_id, owner_user_id=user.id,
                      title=clean_text(data.title))
        db.add(row)
        db.commit()
        db.refresh(row)
        return ExamOut.model_validate(row, from_attributes=True)

    @app.put("/api/v1/exams/{exam_id}/result", response_model=ExamOut)
    def record_exam(exam_id: str, data: ExamResultIn,
                    user: User = Depends(current_user), db: Session = Depends(get_db)):
        dev_write_only()
        row = db.scalar(select(LabExam).where(
            LabExam.id == exam_id, LabExam.owner_user_id == user.id)
            .with_for_update())
        if row is None:
            raise HTTPException(status_code=404, detail="Examen introuvable")
        if row.status != "pending":
            raise HTTPException(status_code=409, detail="Examen déjà clôturé")
        row.result = clean_text(data.result)
        row.result_recorded_at = datetime.now(timezone.utc)
        row.status = "complete"
        db.commit()
        db.refresh(row)
        return ExamOut.model_validate(row, from_attributes=True)

    @app.get("/api/v1/patients/{patient_id}/followups",
             response_model=list[FollowUpOut])
    def list_followups(patient_id: str, user: User = Depends(current_user),
                       db: Session = Depends(get_db)):
        owned_patient(db, user, patient_id)
        records = db.scalars(select(FollowUp).where(
            FollowUp.patient_id == patient_id, FollowUp.owner_user_id == user.id)
            .order_by(FollowUp.scheduled_at.asc())).all()
        return [FollowUpOut.model_validate(item, from_attributes=True) for item in records]

    @app.post("/api/v1/patients/{patient_id}/followups",
              response_model=FollowUpOut, status_code=201)
    def create_followup(patient_id: str, data: FollowUpIn,
                        user: User = Depends(current_user), db: Session = Depends(get_db)):
        dev_write_only()
        owned_patient(db, user, patient_id)
        row = FollowUp(patient_id=patient_id, owner_user_id=user.id,
                       **(data.model_dump() | {"reason": clean_text(data.reason)}))
        db.add(row)
        db.commit()
        db.refresh(row)
        return FollowUpOut.model_validate(row, from_attributes=True)

    @app.put("/api/v1/followups/{followup_id}/reschedule",
             response_model=FollowUpOut)
    def reschedule_followup(followup_id: str, data: FollowUpIn,
                            user: User = Depends(current_user),
                            db: Session = Depends(get_db)):
        dev_write_only()
        row = db.scalar(select(FollowUp).where(
            FollowUp.id == followup_id, FollowUp.owner_user_id == user.id)
            .with_for_update())
        if row is None:
            raise HTTPException(status_code=404, detail="Suivi introuvable")
        if row.status != "planned":
            raise HTTPException(status_code=409, detail="Suivi déjà clôturé")
        row.scheduled_at = data.scheduled_at
        row.reason = clean_text(data.reason)
        row.notes = data.notes
        db.commit()
        db.refresh(row)
        return FollowUpOut.model_validate(row, from_attributes=True)

    @app.put("/api/v1/followups/{followup_id}/close",
             response_model=FollowUpOut)
    def close_followup(followup_id: str, data: CloseFollowUpIn,
                       user: User = Depends(current_user),
                       db: Session = Depends(get_db)):
        dev_write_only()
        row = db.scalar(select(FollowUp).where(
            FollowUp.id == followup_id, FollowUp.owner_user_id == user.id)
            .with_for_update())
        if row is None:
            raise HTTPException(status_code=404, detail="Suivi introuvable")
        if row.status != "planned":
            raise HTTPException(status_code=409, detail="Suivi déjà clôturé")
        row.status = "completed" if data.completed else "cancelled"
        row.completed_at = datetime.now(timezone.utc) if data.completed else None
        db.commit()
        db.refresh(row)
        return FollowUpOut.model_validate(row, from_attributes=True)

    return app


app = api_app()
