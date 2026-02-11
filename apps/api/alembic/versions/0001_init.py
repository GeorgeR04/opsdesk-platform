import sqlalchemy as sa

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "changes",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("title", sa.String(length=256), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.Float(), nullable=False),
    )
    op.create_table(
        "stats",
        sa.Column("id", sa.String(length=64), primary_key=True),
        sa.Column("lead_time_avg_minutes", sa.Float(), nullable=False),
        sa.Column("change_failure_rate", sa.Float(), nullable=False),
        sa.Column("mttr_minutes", sa.Float(), nullable=False),
        sa.Column("updated_at", sa.Float(), nullable=False),
    )


def downgrade():
    op.drop_table("stats")
    op.drop_table("changes")
