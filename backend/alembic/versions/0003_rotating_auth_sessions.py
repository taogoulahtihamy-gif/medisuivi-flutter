"""Per-device sessions with rotated refresh secrets.

Revision ID: 0003
Revises: 0002
Create Date: 2026-10-14
"""
from alembic import op
import sqlalchemy as sa

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None

def upgrade():
    op.create_table("auth_sessions",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("user_id", sa.String(36), nullable=False),
        sa.Column("session_version", sa.Integer(), nullable=False),
        sa.Column("refresh_digest", sa.String(64), nullable=False),
        sa.Column("previous_digest", sa.String(64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
    )
    op.create_index("ix_auth_sessions_user_id", "auth_sessions", ["user_id"])

def downgrade():
    raise RuntimeError("Refusing destructive downgrade of practitioner sessions")
