from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.customer import Customer


class AIInsight(Base):
    __tablename__ = "ai_insights"
    __table_args__ = (Index("ix_ai_insights_priority_score", "priority_score"),)

    customer_id: Mapped[str] = mapped_column(
        String(20), ForeignKey("customers.id"), primary_key=True
    )
    summary: Mapped[str | None] = mapped_column(Text)
    next_action: Mapped[str | None] = mapped_column(Text)
    priority_score: Mapped[int | None] = mapped_column(Integer)
    priority_reason: Mapped[str | None] = mapped_column(Text)
    generated_at: Mapped[datetime | None] = mapped_column(DateTime)

    customer: Mapped["Customer"] = relationship(back_populates="insight")
