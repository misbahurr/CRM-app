from __future__ import annotations

import csv
import os
from datetime import date
from pathlib import Path

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.ai_insight import AIInsight
from app.models.contact import Contact
from app.models.customer import Customer
from app.models.interaction import Interaction

DATA_DIR = Path(__file__).resolve().parent / "data"


def _read(name: str) -> list[dict[str, str]]:
    path = DATA_DIR / name
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def seed(db: Session, *, force: bool = False) -> None:
    existing = db.query(Customer).count()
    if existing and not force:
        print(f"Database already has {existing} customers. Skipping (set FORCE_SEED=1 to reload).")
        return

    if force:
        db.query(AIInsight).delete()
        db.query(Interaction).delete()
        db.query(Contact).delete()
        db.query(Customer).delete()
        db.commit()

    for row in _read("customers.csv"):
        db.add(
            Customer(
                id=row["id"],
                name=row["name"],
                status=row["status"],
                created_at=date.fromisoformat(row["created_at"]),
            )
        )
    db.flush()

    for row in _read("contacts.csv"):
        db.add(
            Contact(
                id=row["id"],
                customer_id=row["customer_id"],
                name=row["name"],
                email=row["email"] or None,
                role=row["role"] or None,
            )
        )
    db.flush()

    for row in _read("interactions.csv"):
        db.add(
            Interaction(
                id=row["id"],
                customer_id=row["customer_id"],
                contact_id=row["contact_id"],
                type=row["type"],
                occurred_at=date.fromisoformat(row["occurred_at"]),
                notes=row["notes"] or None,
            )
        )
    db.commit()
    print("Seeded customers, contacts, and interactions.")


def maybe_generate_insights(db: Session) -> None:
    from app.services.customer_service import CustomerService

    service = CustomerService(db)
    if not service.ai_service.enabled:
        print("OPENAI_API_KEY not set; skipping insight generation (will run on first request).")
        return

    customers = db.query(Customer).all()
    for customer in customers:
        print(f"Generating insights for {customer.name}...")
        try:
            service.refresh_insights(customer.id)
        except Exception as exc:
            print(f"  failed: {exc}")
    print("Insight generation finished.")


def main() -> None:
    force = os.getenv("FORCE_SEED") == "1"
    db = SessionLocal()
    try:
        seed(db, force=force)
        maybe_generate_insights(db)
    finally:
        db.close()


if __name__ == "__main__":
    main()
