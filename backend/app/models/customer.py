from datetime import date
from typing import TYPE_CHECKING

from sqlalchemy import Date, Enum, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.ai_insight import AIInsight
    from app.models.contact import Contact
    from app.models.interaction import Interaction


class Customer(Base):
    __tablename__ = "customers"
    __table_args__ = (
        Index("ix_customers_status", "status"),
        Index("ix_customers_name", "name"),
    )

    id: Mapped[str] = mapped_column(String(20), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[str] = mapped_column(
        Enum("prospect", "customer", name="customer_status"),
        nullable=False,
    )
    created_at: Mapped[date] = mapped_column(Date, nullable=False)

    contacts: Mapped[list["Contact"]] = relationship(back_populates="customer")
    interactions: Mapped[list["Interaction"]] = relationship(back_populates="customer")
    insight: Mapped["AIInsight | None"] = relationship(back_populates="customer")
