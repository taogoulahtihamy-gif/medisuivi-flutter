"""Create authenticated practitioners and owner-isolated clinical tables.

Revision ID: 0001
Revises:
Create Date: 2026-10-14
NOTE: initial schema for fresh dev DB, does not import/migrate Flutter data.
"""
from alembic import op
import sqlalchemy as sa

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "practitioners",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("email", sa.String(320), nullable=False),
        sa.Column("password_hash", sa.String(512), nullable=False),
        sa.Column("first_name", sa.String(120), nullable=False),
        sa.Column("last_name", sa.String(120), nullable=False),
        sa.Column("active", sa.Boolean(), nullable=False),
        sa.Column("session_version", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_practitioners_email", "practitioners", ["email"], unique=True)

    op.create_table(
        "patients",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("owner_user_id", sa.String(36), nullable=False),
        sa.Column("display_name", sa.String(180), nullable=False),
        sa.Column("age", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["owner_user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
        sa.UniqueConstraint("id", "owner_user_id", name="uq_patient_id_owner"),
    )
    op.create_index("ix_patients_owner_user_id", "patients", ["owner_user_id"])

    op.create_table(
        "visits",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("owner_user_id", sa.String(36), nullable=False),
        sa.Column("patient_id", sa.String(36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reason", sa.String(500), nullable=False),
        sa.Column("temperature", sa.Float()),
        sa.Column("systolic", sa.Integer()),
        sa.Column("diastolic", sa.Integer()),
        sa.Column("pulse", sa.Integer()),
        sa.Column("spo2", sa.Integer()),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.ForeignKeyConstraint(["owner_user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_visits_patient_owner"),
    )
    op.create_index("ix_visits_owner_user_id", "visits", ["owner_user_id"])
    op.create_index("ix_visits_patient_id", "visits", ["patient_id"])

    op.create_table(
        "exams",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("owner_user_id", sa.String(36), nullable=False),
        sa.Column("patient_id", sa.String(36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("title", sa.String(300), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("result", sa.Text()),
        sa.Column("result_recorded_at", sa.DateTime(timezone=True)),
        sa.ForeignKeyConstraint(["owner_user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_exams_patient_owner"),
        sa.CheckConstraint("status IN ('pending','complete')", name="ck_exam_status"),
    )
    op.create_index("ix_exams_owner_user_id", "exams", ["owner_user_id"])
    op.create_index("ix_exams_patient_id", "exams", ["patient_id"])

    op.create_table(
        "followups",
        sa.Column("id", sa.String(36), primary_key=True, nullable=False),
        sa.Column("owner_user_id", sa.String(36), nullable=False),
        sa.Column("patient_id", sa.String(36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reason", sa.String(500), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False),
        sa.Column("status", sa.String(16), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True)),
        sa.ForeignKeyConstraint(["owner_user_id"], ["practitioners.id"],
                                ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(
            ["patient_id", "owner_user_id"], ["patients.id", "patients.owner_user_id"],
            ondelete="RESTRICT", name="fk_followups_patient_owner"),
        sa.CheckConstraint(
            "status IN ('planned','completed','cancelled')", name="ck_followup_status"),
    )
    op.create_index("ix_followups_owner_user_id", "followups", ["owner_user_id"])
    op.create_index("ix_followups_patient_id", "followups", ["patient_id"])


def downgrade() -> None:
    # Refuse destructive downgrade of clinical data, even in development.
    raise RuntimeError("Refusing destructive downgrade of MediSuivi clinical records")
