from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.repositories.interaction import InteractionRepository
from app.schemas.customer import InteractionOut

router = APIRouter(tags=["interactions"])


@router.get("/interactions", response_model=list[InteractionOut])
def list_interactions(
    customer_id: str = Query(..., alias="customer_id"),
    db: Session = Depends(get_db),
) -> list[InteractionOut]:
    rows = InteractionRepository(db).get_by_customer(customer_id)
    return [
        InteractionOut(
            id=item.id,
            customer_id=item.customer_id,
            contact_id=item.contact_id,
            contact_name=item.contact.name if item.contact else None,
            type=item.type,
            occurred_at=item.occurred_at,
            notes=item.notes,
        )
        for item in rows
    ]
