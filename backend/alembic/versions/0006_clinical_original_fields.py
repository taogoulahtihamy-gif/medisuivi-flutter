"""Add optional original MediSuivi clinical fields for SYNTHETIC records.

Revision ID: 0006
Revises: 0005

Additive migration only. Do not use with real clinical data until security,
backup and medical-data compliance reviews are completed.
"""
from alembic import op
import sqlalchemy as sa

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("patients", sa.Column(
        "sex", sa.String(1), nullable=False, server_default="N"))
    op.add_column("patients", sa.Column(
        "phone", sa.String(25), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "allergies", sa.String(1000), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "medical_history", sa.String(4000), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "follow_up", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("patients", sa.Column(
        "profile", sa.JSON(), nullable=False, server_default=sa.text("'{}'")))
    op.add_column("visits", sa.Column(
        "intake", sa.JSON(), nullable=False, server_default=sa.text("'{}'")))


def downgrade() -> None:
    raise RuntimeError("Refusing destructive downgrade of clinical fields")
