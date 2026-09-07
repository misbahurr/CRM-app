from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.models.customer import Customer


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
