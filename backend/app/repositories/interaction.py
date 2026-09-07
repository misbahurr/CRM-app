from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.models.interaction import Interaction


class InteractionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_customer(
        self,
        customer_id: str,
        *,
        limit: int | None = None,
        offset: int = 0,
    ) -> list[Interaction]:
        stmt = (
            select(Interaction)
            .options(selectinload(Interaction.contact))
            .where(Interaction.customer_id == customer_id)
            .order_by(Interaction.occurred_at.desc(), Interaction.id.desc())
        )
        if limit is not None:
            stmt = stmt.limit(limit).offset(offset)
        return list(self.db.scalars(stmt).all())

    def count_by_customer(self, customer_id: str) -> int:
        stmt = (
            select(func.count())
            .select_from(Interaction)
            .where(Interaction.customer_id == customer_id)
        )
        return int(self.db.scalar(stmt) or 0)

    def get_recent(self, customer_id: str, limit: int = 5) -> list[Interaction]:
        return self.get_by_customer(customer_id, limit=limit, offset=0)
