"""add_views

Revision ID: 4bdbcd5a742e
Revises: 27e25c59caa3
Create Date: 2026-08-31 20:34:22.782087

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4bdbcd5a742e'
down_revision: Union[str, Sequence[str], None] = '27e25c59caa3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.execute("""
    CREATE VIEW user_savings_totals AS
    SELECT
        user_id,
        SUM(total_diverted) AS total_saved
    FROM transactions
    GROUP BY user_id;
    """)

    op.execute("""
    CREATE VIEW goal_progress AS
    SELECT
        goal_id,
        SUM(total_diverted) AS current_amount
    FROM transactions
    WHERE goal_id IS NOT NULL
    GROUP BY goal_id;
    """)


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("DROP VIEW IF EXISTS goal_progress;")
    op.execute("DROP VIEW IF EXISTS user_savings_totals;")
