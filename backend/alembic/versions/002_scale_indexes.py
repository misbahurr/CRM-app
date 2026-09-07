"""Add indexes for list filters, priority sort, and FK lookups.

Revision ID: 002_scale_indexes
Revises: 001_initial
Create Date: 2026-09-07
"""

from typing import Sequence, Union

from alembic import op

revision: str = "002_scale_indexes"
down_revision: Union[str, Sequence[str], None] = "001_initial"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index("ix_customers_status", "customers", ["status"])
    op.create_index("ix_customers_name", "customers", ["name"])
    op.create_index("ix_ai_insights_priority_score", "ai_insights", ["priority_score"])
    op.create_index("ix_interactions_contact_id", "interactions", ["contact_id"])
    op.create_index("ix_contacts_email", "contacts", ["email"])


def downgrade() -> None:
    op.drop_index("ix_contacts_email", table_name="contacts")
    op.drop_index("ix_interactions_contact_id", table_name="interactions")
    op.drop_index("ix_ai_insights_priority_score", table_name="ai_insights")
    op.drop_index("ix_customers_name", table_name="customers")
    op.drop_index("ix_customers_status", table_name="customers")
