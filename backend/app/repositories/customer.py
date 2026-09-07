from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Literal

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.ai_insight import AIInsight
from app.models.customer import Customer
from app.models.interaction import Interaction
from app.services.priority_service import ATTENTION_MIN

ListFilter = Literal["all", "attention", "prospects", "customers"]


@dataclass
class CustomerListRow:
    customer: Customer
    insight: AIInsight | None
    last_interaction_at: date | None


class CustomerRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_all(self) -> list[Customer]:
        stmt = select(Customer).order_by(Customer.name)
        return list(self.db.scalars(stmt).all())

    def get_by_id(self, customer_id: str) -> Customer | None:
        return self.db.get(Customer, customer_id)

    def get_with_relations(self, customer_id: str) -> Customer | None:
        stmt = (
            select(Customer)
            .options(
                selectinload(Customer.contacts),
                selectinload(Customer.interactions),
            )
            .where(Customer.id == customer_id)
        )
        return self.db.scalars(stmt).first()

    def list_page(
        self,
        *,
        list_filter: ListFilter = "all",
        limit: int = 20,
        offset: int = 0,
    ) -> list[CustomerListRow]:
        last_at = (
            select(func.max(Interaction.occurred_at))
            .where(Interaction.customer_id == Customer.id)
            .correlate(Customer)
            .scalar_subquery()
        )
        stmt = (
            select(Customer, AIInsight, last_at.label("last_interaction_at"))
            .outerjoin(AIInsight, AIInsight.customer_id == Customer.id)
        )
        stmt = self._apply_filter(stmt, list_filter)
        stmt = (
            stmt.order_by(
                func.coalesce(AIInsight.priority_score, -1).desc(),
                Customer.name.asc(),
            )
            .limit(limit)
            .offset(offset)
        )
        rows: list[CustomerListRow] = []
        for customer, insight, last_interaction_at in self.db.execute(stmt):
            rows.append(
                CustomerListRow(
                    customer=customer,
                    insight=insight,
                    last_interaction_at=last_interaction_at,
                )
            )
        return rows

    def count_filtered(self, list_filter: ListFilter = "all") -> int:
        stmt = (
            select(func.count())
            .select_from(Customer)
            .outerjoin(AIInsight, AIInsight.customer_id == Customer.id)
        )
        stmt = self._apply_filter(stmt, list_filter)
        return int(self.db.scalar(stmt) or 0)

    def filter_counts(self) -> dict[str, int]:
        all_count = int(
            self.db.scalar(select(func.count()).select_from(Customer)) or 0
        )
        prospects = int(
            self.db.scalar(
                select(func.count()).select_from(Customer).where(Customer.status == "prospect")
            )
            or 0
        )
        customers = int(
            self.db.scalar(
                select(func.count()).select_from(Customer).where(Customer.status == "customer")
            )
            or 0
        )
        attention = int(
            self.db.scalar(
                select(func.count())
                .select_from(AIInsight)
                .where(AIInsight.priority_score >= ATTENTION_MIN)
            )
            or 0
        )
        return {
            "all": all_count,
            "attention": attention,
            "prospects": prospects,
            "customers": customers,
        }

    @staticmethod
    def _apply_filter(stmt, list_filter: ListFilter):
        if list_filter == "prospects":
            return stmt.where(Customer.status == "prospect")
        if list_filter == "customers":
            return stmt.where(Customer.status == "customer")
        if list_filter == "attention":
            return stmt.where(AIInsight.priority_score >= ATTENTION_MIN)
        return stmt
