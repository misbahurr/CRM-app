"""Initial schema: customers, contacts, interactions, ai_insights.

Revision ID: 001_initial
Revises:
Create Date: 2026-09-07
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "001_initial"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "customers",
        sa.Column("id", sa.String(20), primary_key=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column(
            "status",
            sa.Enum("prospect", "customer", name="customer_status"),
            nullable=False,
        ),
        sa.Column("created_at", sa.Date(), nullable=False),
    )
    op.create_table(
        "contacts",
        sa.Column("id", sa.String(20), primary_key=True),
        sa.Column("customer_id", sa.String(20), sa.ForeignKey("customers.id"), nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("email", sa.String(255)),
        sa.Column("role", sa.String(100)),
    )
    op.create_index("ix_contacts_customer_id", "contacts", ["customer_id"])
    op.create_table(
        "interactions",
        sa.Column("id", sa.String(20), primary_key=True),
        sa.Column("customer_id", sa.String(20), sa.ForeignKey("customers.id"), nullable=False),
        sa.Column("contact_id", sa.String(20), sa.ForeignKey("contacts.id"), nullable=False),
        sa.Column(
            "type",
            sa.Enum("email", "call", "meeting", "note", name="interaction_type"),
            nullable=False,
        ),
        sa.Column("occurred_at", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text()),
    )
    op.create_index(
        "ix_interactions_customer_occurred",
        "interactions",
        ["customer_id", "occurred_at"],
    )
    op.create_table(
        "ai_insights",
        sa.Column(
            "customer_id",
            sa.String(20),
            sa.ForeignKey("customers.id"),
            primary_key=True,
        ),
        sa.Column("summary", sa.Text()),
        sa.Column("next_action", sa.Text()),
        sa.Column("priority_score", sa.Integer()),
        sa.Column("priority_reason", sa.Text()),
        sa.Column("generated_at", sa.DateTime()),
    )


def downgrade() -> None:
    op.drop_table("ai_insights")
    op.drop_index("ix_interactions_customer_occurred", table_name="interactions")
    op.drop_table("interactions")
    op.drop_index("ix_contacts_customer_id", table_name="contacts")
    op.drop_table("contacts")
    op.drop_table("customers")
