from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.interaction import Interaction


class InteractionRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_customer(self, customer_id: str) -> list[Interaction]:
        stmt = (
            select(Interaction)
            .options(selectinload(Interaction.contact))
            .where(Interaction.customer_id == customer_id)
            .order_by(Interaction.occurred_at.desc(), Interaction.id.desc())
        )
        return list(self.db.scalars(stmt).all())

    def get_recent(self, customer_id: str, limit: int = 5) -> list[Interaction]:
        stmt = (
            select(Interaction)
            .options(selectinload(Interaction.contact))
            .where(Interaction.customer_id == customer_id)
            .order_by(Interaction.occurred_at.desc())
            .limit(limit)
        )
        return list(self.db.scalars(stmt).all())
