"""P4.9: additive fields required by the ORIGINAL MediSuivi clinical screens.

No existing rows are deleted, no accounts or owner IDs are changed.
The migration preserves all legacy synthetic records.
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
        "phone", sa.String(40), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "allergies", sa.Text(), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "medical_history", sa.Text(), nullable=False, server_default=""))
    op.add_column("patients", sa.Column(
        "follow_up", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column("patients", sa.Column(
        "profile_json", sa.JSON(), nullable=True))
    op.add_column("visits", sa.Column(
        "intake_json", sa.JSON(), nullable=True))


def downgrade() -> None:
    raise RuntimeError(
        "Refusing downgrade that would erase clinical supplement fields")
