"""Email verification / password recovery challenge ledger.

Revision ID: 0005
Revises: 0004
"""
from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "practitioners",
        sa.Column("email_verified", sa.Boolean(), nullable=False,
                  server_default=sa.true()),
    )
    # Existing synthetic accounts remain verified in the development
    # baseline; all NEW signups must verify when email flow is enabled.
    op.create_table(
        "email_challenges",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("user_id", sa.String(36), nullable=False),
        sa.Column("purpose", sa.String(20), nullable=False),
        sa.Column("code_digest", sa.String(64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("consumed_at", sa.DateTime(timezone=True)),
        sa.Column("failed_attempts", sa.Integer(), nullable=False,
                  server_default="0"),
        sa.ForeignKeyConstraint(["user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
        sa.CheckConstraint("purpose IN ('verify_email','reset_password')",
                           name="ck_email_challenge_purpose"),
        sa.CheckConstraint("failed_attempts >= 0",
                           name="ck_email_challenge_attempts"),
    )
    op.create_index("ix_email_challenges_user_id", "email_challenges",
                    ["user_id"])


def downgrade() -> None:
    raise RuntimeError("Refusing destructive downgrade of identity challenges")
