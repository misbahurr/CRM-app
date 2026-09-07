from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.repositories.interaction import InteractionRepository
from app.schemas.customer import InteractionListOut, InteractionOut

router = APIRouter(tags=["interactions"])


@router.get("/interactions", response_model=InteractionListOut)
def list_interactions(
    customer_id: str = Query(..., alias="customer_id"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
) -> InteractionListOut:
    repo = InteractionRepository(db)
    total = repo.count_by_customer(customer_id)
    rows = repo.get_by_customer(customer_id, limit=limit, offset=offset)
    items = [
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
    return InteractionListOut(
        items=items,
        total=total,
        limit=limit,
        offset=offset,
        has_more=offset + len(items) < total,
    )
