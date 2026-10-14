"""Rate-limit login attempts without persisting plaintext account identifiers.

Revision ID: 0004
Revises: 0003
Create Date: 2026-10-14

Only dev/test/staging use this schema; this prototype rejects production.
"""
from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "login_attempts",
        sa.Column("key", sa.String(length=64), primary_key=True, nullable=False),
        sa.Column("failed_count", sa.Integer(), nullable=False),
        sa.Column("window_started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("blocked_until", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("failed_count >= 0", name="ck_login_failed_count_positive"),
    )


def downgrade() -> None:
    raise RuntimeError("Refusing implicit removal of login abuse protection state")
