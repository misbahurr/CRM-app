from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, Enum, ForeignKey, Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.contact import Contact
    from app.models.customer import Customer


class Interaction(Base):
    __tablename__ = "interactions"
    __table_args__ = (
        Index("ix_interactions_customer_occurred", "customer_id", "occurred_at"),
    )

    id: Mapped[str] = mapped_column(String(20), primary_key=True)
    customer_id: Mapped[str] = mapped_column(
        String(20), ForeignKey("customers.id"), nullable=False
    )
    contact_id: Mapped[str] = mapped_column(
        String(20), ForeignKey("contacts.id"), nullable=False
    )
    type: Mapped[str] = mapped_column(
        Enum("email", "call", "meeting", "note", name="interaction_type"),
        nullable=False,
    )
    occurred_at: Mapped[date] = mapped_column(Date, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text)

    customer: Mapped["Customer"] = relationship(back_populates="interactions")
    contact: Mapped["Contact"] = relationship(back_populates="interactions")
