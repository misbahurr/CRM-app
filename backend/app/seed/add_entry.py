"""Add a customer (plus contacts and interactions) via the existing SQLAlchemy models.

Examples (from backend/, venv active):

  python -m app.seed.add_entry --list

  python -m app.seed.add_entry --file app/seed/data/example_entry.json

  python -m app.seed.add_entry \\
    --name "Sunrise Family Dentistry" --status prospect \\
    --contact-name "Anna Reyes" --email anna@sunrisefamily.example --role Owner \\
    --type email --occurred-at 2026-09-01 \\
    --notes "Anna asked for pricing and wanted a demo next week."
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import date
from pathlib import Path

from sqlalchemy.orm import Session

from app.database import SessionLocal
from app.models.contact import Contact
from app.models.customer import Customer
from app.models.interaction import Interaction

CUSTOMER_STATUSES = {"prospect", "customer"}
INTERACTION_TYPES = {"email", "call", "meeting", "note"}
ID_MAX = 20


def _next_id(db: Session, model, prefix: str) -> str:
    rows = db.query(model.id).all()
    highest = 0
    pattern = re.compile(rf"^{re.escape(prefix)}_(\d+)$")
    for (value,) in rows:
        match = pattern.match(value or "")
        if match:
            highest = max(highest, int(match.group(1)))
    return f"{prefix}_{highest + 1:03d}"


def _require_unique(db: Session, model, row_id: str, label: str) -> None:
    if len(row_id) > ID_MAX:
        raise ValueError(f"{label} id {row_id!r} is longer than {ID_MAX} characters")
    if db.get(model, row_id) is not None:
        raise ValueError(f"{label} id {row_id!r} already exists")


def add_entry(
    db: Session,
    *,
    customer: dict,
    contacts: list[dict],
    interactions: list[dict],
    generate_insights: bool = False,
) -> str:
    status = customer["status"]
    if status not in CUSTOMER_STATUSES:
        raise ValueError(f"status must be one of {sorted(CUSTOMER_STATUSES)}")

    customer_id = customer.get("id") or _next_id(db, Customer, "cust")
    _require_unique(db, Customer, customer_id, "customer")

    created_at = customer.get("created_at") or date.today().isoformat()
    db.add(
        Customer(
            id=customer_id,
            name=customer["name"],
            status=status,
            created_at=date.fromisoformat(created_at),
        )
    )
    db.flush()

    contact_ids: dict[str, str] = {}
    for index, raw in enumerate(contacts, start=1):
        contact_id = raw.get("id") or _next_id(db, Contact, "contact")
        if contact_id in contact_ids.values():
            contact_id = _next_id(db, Contact, "contact")
        _require_unique(db, Contact, contact_id, "contact")
        key = raw.get("key") or raw.get("id") or f"contact-{index}"
        contact_ids[key] = contact_id
        db.add(
            Contact(
                id=contact_id,
                customer_id=customer_id,
                name=raw["name"],
                email=raw.get("email") or None,
                role=raw.get("role") or None,
            )
        )
        db.flush()

    if not contact_ids:
        raise ValueError("at least one contact is required")

    default_contact = next(iter(contact_ids.values()))
    for raw in interactions:
        itype = raw["type"]
        if itype not in INTERACTION_TYPES:
            raise ValueError(f"interaction type must be one of {sorted(INTERACTION_TYPES)}")
        interaction_id = raw.get("id") or _next_id(db, Interaction, "int")
        _require_unique(db, Interaction, interaction_id, "interaction")
        contact_ref = raw.get("contact_id") or raw.get("contact") or default_contact
        contact_id = contact_ids.get(contact_ref, contact_ref)
        if db.get(Contact, contact_id) is None:
            raise ValueError(f"unknown contact_id {contact_ref!r}")
        db.add(
            Interaction(
                id=interaction_id,
                customer_id=customer_id,
                contact_id=contact_id,
                type=itype,
                occurred_at=date.fromisoformat(raw["occurred_at"]),
                notes=raw.get("notes") or None,
            )
        )
        db.flush()

    db.commit()

    if generate_insights:
        from app.services.customer_service import CustomerService

        service = CustomerService(db)
        if service.ai_service.enabled:
            service.refresh_insights(customer_id)
        else:
            print("OPENAI_API_KEY not set; insights will generate on first request.")

    return customer_id


def list_customers(db: Session) -> None:
    rows = db.query(Customer).order_by(Customer.id).all()
    if not rows:
        print("No customers yet.")
        return
    print(f"{'id':<10} {'status':<10} name")
    for row in rows:
        print(f"{row.id:<10} {row.status:<10} {row.name}")


def _from_cli_args(args: argparse.Namespace) -> tuple[dict, list[dict], list[dict]]:
    if not args.name or not args.contact_name or not args.type or not args.notes:
        raise ValueError(
            "one-shot mode needs --name, --contact-name, --type, --occurred-at, and --notes"
        )
    customer = {
        "id": args.customer_id,
        "name": args.name,
        "status": args.status,
        "created_at": args.created_at or date.today().isoformat(),
    }
    contacts = [
        {
            "id": args.contact_id,
            "name": args.contact_name,
            "email": args.email,
            "role": args.role,
        }
    ]
    interactions = [
        {
            "id": args.interaction_id,
            "type": args.type,
            "occurred_at": args.occurred_at or date.today().isoformat(),
            "notes": args.notes,
        }
    ]
    return customer, contacts, interactions


def main() -> None:
    parser = argparse.ArgumentParser(description="Insert a customer, contacts, and interactions.")
    parser.add_argument("--list", action="store_true", help="Print existing customers and exit")
    parser.add_argument("--file", type=Path, help="JSON file with customer, contacts, interactions")
    parser.add_argument("--customer-id")
    parser.add_argument("--name")
    parser.add_argument("--status", default="prospect", choices=sorted(CUSTOMER_STATUSES))
    parser.add_argument("--created-at")
    parser.add_argument("--contact-id")
    parser.add_argument("--contact-name")
    parser.add_argument("--email")
    parser.add_argument("--role")
    parser.add_argument("--interaction-id")
    parser.add_argument("--type", dest="type", choices=sorted(INTERACTION_TYPES))
    parser.add_argument("--occurred-at")
    parser.add_argument("--notes")
    parser.add_argument(
        "--insights",
        action="store_true",
        help="Generate AI insights immediately if a key is configured",
    )
    args = parser.parse_args()

    db = SessionLocal()
    try:
        if args.list:
            list_customers(db)
            return
        if args.file:
            payload = json.loads(args.file.read_text(encoding="utf-8"))
            customer = payload["customer"]
            contacts = payload.get("contacts") or []
            interactions = payload.get("interactions") or []
            generate = bool(payload.get("generate_insights") or args.insights)
        else:
            customer, contacts, interactions = _from_cli_args(args)
            generate = args.insights
        customer_id = add_entry(
            db,
            customer=customer,
            contacts=contacts,
            interactions=interactions,
            generate_insights=generate,
        )
        print(f"Added customer {customer_id}. Refresh the priority feed to see it.")
    except (KeyError, ValueError, json.JSONDecodeError) as exc:
        print(f"Could not add entry: {exc}", file=sys.stderr)
        sys.exit(1)
    finally:
        db.close()


if __name__ == "__main__":
    main()
