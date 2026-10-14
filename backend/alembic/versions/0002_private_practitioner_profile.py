"""Add private practitioner profile and photo (development-only).

Revision ID: 0002
Revises: 0001
Create Date: 2026-10-14
"""
from alembic import op
import sqlalchemy as sa

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None

def upgrade():
    op.add_column("practitioners", sa.Column("phone", sa.String(length=25),
       nullable=False, server_default=""))
    op.add_column("practitioners", sa.Column("specialty", sa.String(length=120),
       nullable=False, server_default=""))
    op.add_column("practitioners", sa.Column("avatar_webp", sa.LargeBinary(),
       nullable=True))
    op.alter_column("practitioners", "phone", server_default=None)
    op.alter_column("practitioners", "specialty", server_default=None)

def downgrade():
    raise RuntimeError("Refusing destructive migration of practitioner profile")
