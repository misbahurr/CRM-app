from datetime import date

from pydantic import BaseModel


class ContactOut(BaseModel):
    id: str
    customer_id: str
    name: str
    email: str | None
    role: str | None

    model_config = {"from_attributes": True}


class InteractionOut(BaseModel):
    id: str
    customer_id: str
    contact_id: str
    contact_name: str | None = None
    type: str
    occurred_at: date
    notes: str | None

    model_config = {"from_attributes": True}


class CustomerSummaryOut(BaseModel):
    id: str
    name: str
    status: str
    created_at: date
    priority_score: int
    priority_reason: str
    last_interaction_at: date | None
    days_since_last: int | None


class CustomerDetailOut(BaseModel):
    id: str
    name: str
    status: str
    created_at: date
    contacts: list[ContactOut]
    interactions: list[InteractionOut]


class InsightOut(BaseModel):
    customer_id: str
    summary: str | None
    next_action: str | None
    drafted_message: str | None = None
    priority_score: int | None
    priority_reason: str | None
    generated_at: str | None
