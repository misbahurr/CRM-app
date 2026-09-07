from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.customer import (
    CustomerDetailOut,
    CustomerListOut,
    InsightOut,
)
from app.services.customer_service import CustomerService

router = APIRouter(tags=["customers"])

ListFilter = Literal["all", "attention", "prospects", "customers"]


def _service(db: Session = Depends(get_db)) -> CustomerService:
    return CustomerService(db)


@router.get("/customers", response_model=CustomerListOut)
def list_customers(
    list_filter: ListFilter = Query("all", alias="filter"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    service: CustomerService = Depends(_service),
) -> CustomerListOut:
    return service.list_customers_with_priority(
        list_filter=list_filter, limit=limit, offset=offset
    )


@router.get("/customers/{customer_id}", response_model=CustomerDetailOut)
def get_customer(
    customer_id: str, service: CustomerService = Depends(_service)
) -> CustomerDetailOut:
    detail = service.get_customer_detail(customer_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return detail


@router.get("/customers/{customer_id}/insights", response_model=InsightOut)
def get_insights(
    customer_id: str, service: CustomerService = Depends(_service)
) -> InsightOut:
    insight = service.get_or_generate_insights(customer_id)
    if insight is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return insight


@router.post("/customers/{customer_id}/insights/refresh", response_model=InsightOut)
def refresh_insights(
    customer_id: str, service: CustomerService = Depends(_service)
) -> InsightOut:
    insight = service.refresh_insights(customer_id)
    if insight is None:
        raise HTTPException(status_code=404, detail="Customer not found")
    return insight
