from __future__ import annotations

import json

from datetime import date

from sqlalchemy.orm import Session

from app.models.ai_insight import AIInsight
from app.models.customer import Customer
from app.models.interaction import Interaction
from app.repositories.ai_insight import AIInsightRepository
from app.repositories.customer import CustomerRepository, ListFilter
from app.repositories.interaction import InteractionRepository
from app.schemas.customer import (
    ContactOut,
    CustomerDetailOut,
    CustomerListOut,
    CustomerSummaryOut,
    FilterCountsOut,
    InsightOut,
    InteractionOut,
)
from app.services.ai_service import AIService
from app.services.priority_service import PriorityService


class CustomerService:
    def __init__(self, db: Session) -> None:
        self.customer_repo = CustomerRepository(db)
        self.interaction_repo = InteractionRepository(db)
        self.insight_repo = AIInsightRepository(db)
        self.ai_service = AIService()
        self.priority_service = PriorityService(self.ai_service)

    def list_customers_with_priority(
        self,
        *,
        list_filter: ListFilter = "all",
        limit: int = 20,
        offset: int = 0,
    ) -> CustomerListOut:
        rows = self.customer_repo.list_page(
            list_filter=list_filter, limit=limit, offset=offset
        )
        summaries: list[CustomerSummaryOut] = []
        for row in rows:
            customer = row.customer
            insight = row.insight
            stale_placeholder = bool(
                insight
                and self.ai_service.enabled
                and (insight.priority_reason or "").startswith("No AI score yet")
            )
            if insight is None or insight.priority_score is None or stale_placeholder:
                interactions = self.interaction_repo.get_by_customer(customer.id)
                insight = self._generate_priority_only(customer, interactions)
                if not row.last_interaction_at and interactions:
                    row.last_interaction_at = max(i.occurred_at for i in interactions)

            last_at = row.last_interaction_at
            days = None if last_at is None else max(0, (date.today() - last_at).days)
            summaries.append(
                CustomerSummaryOut(
                    id=customer.id,
                    name=customer.name,
                    status=customer.status,
                    created_at=customer.created_at,
                    priority_score=insight.priority_score or 0,
                    priority_reason=insight.priority_reason or "No priority reason yet.",
                    last_interaction_at=last_at,
                    days_since_last=days,
                )
            )

        total = self.customer_repo.count_filtered(list_filter)
        counts = self.customer_repo.filter_counts()
        return CustomerListOut(
            items=summaries,
            total=total,
            limit=limit,
            offset=offset,
            has_more=offset + len(summaries) < total,
            counts=FilterCountsOut(**counts),
        )

    def get_customer_detail(self, customer_id: str) -> CustomerDetailOut | None:
        detail = self.customer_repo.get_with_relations(customer_id)
        if detail is None:
            return None
        interactions = self.interaction_repo.get_by_customer(customer_id)
        return CustomerDetailOut(
            id=detail.id,
            name=detail.name,
            status=detail.status,
            created_at=detail.created_at,
            contacts=[
                ContactOut.model_validate(c)
                for c in sorted(detail.contacts, key=lambda c: c.name)
            ],
            interactions=[self._interaction_out(i) for i in interactions],
        )

    def get_or_generate_insights(self, customer_id: str) -> InsightOut | None:
        customer = self.customer_repo.get_by_id(customer_id)
        if customer is None:
            return None
        insight = self.insight_repo.get_by_customer(customer_id)
        if insight and insight.summary:
            return self._insight_out(insight)
        return self.refresh_insights(customer_id)

    def refresh_insights(self, customer_id: str) -> InsightOut | None:
        customer = self.customer_repo.get_by_id(customer_id)
        if customer is None:
            return None
        interactions = self.interaction_repo.get_by_customer(customer_id)
        priority = self.priority_service.compute(customer, interactions)

        summary = None
        action = None
        draft = None
        if self.ai_service.enabled:
            try:
                summary = self.ai_service.generate_summary(interactions)
                next_action = self.ai_service.generate_next_action(summary, interactions)
                action = next_action.action
                draft = next_action.drafted_message
            except Exception:
                summary = summary or self._fallback_summary(customer, interactions)
                action = action or self._fallback_action(interactions)
        else:
            summary = self._fallback_summary(customer, interactions)
            action = self._fallback_action(interactions)

        stored_action = json.dumps({"action": action, "drafted_message": draft})
        row = self.insight_repo.upsert(
            customer_id,
            summary=summary,
            next_action=stored_action,
            priority_score=priority.score,
            priority_reason=priority.reason,
        )
        return self._insight_out(row)

    def _generate_priority_only(
        self, customer: Customer, interactions: list[Interaction]
    ) -> AIInsight:
        try:
            priority = self.priority_service.compute(customer, interactions)
        except Exception:
            days = self.priority_service.days_since_last(interactions)
            score = self.priority_service.recency_score(interactions)
            reason = (
                f"Last contact {days} days ago."
                if days is not None
                else "No interactions on record."
            )
            from app.services.ai_service import PriorityResult

            priority = PriorityResult(score=score, reason=reason)
        return self.insight_repo.upsert(
            customer.id,
            summary=None,
            next_action=None,
            priority_score=priority.score,
            priority_reason=priority.reason,
        )

    def _insight_out(self, insight: AIInsight) -> InsightOut:
        action, draft = self._parse_next_action(insight.next_action)
        generated = insight.generated_at.isoformat() if insight.generated_at else None
        return InsightOut(
            customer_id=insight.customer_id,
            summary=insight.summary,
            next_action=action,
            drafted_message=draft,
            priority_score=insight.priority_score,
            priority_reason=insight.priority_reason,
            generated_at=generated,
        )

    @staticmethod
    def _parse_next_action(raw: str | None) -> tuple[str | None, str | None]:
        if not raw:
            return None, None
        try:
            data = json.loads(raw)
            if isinstance(data, dict):
                action = data.get("action")
                draft = data.get("drafted_message")
                return (
                    str(action) if action else None,
                    str(draft) if draft else None,
                )
        except json.JSONDecodeError:
            pass
        return raw, None

    @staticmethod
    def _interaction_out(item: Interaction) -> InteractionOut:
        return InteractionOut(
            id=item.id,
            customer_id=item.customer_id,
            contact_id=item.contact_id,
            contact_name=item.contact.name if item.contact else None,
            type=item.type,
            occurred_at=item.occurred_at,
            notes=item.notes,
        )

    def _fallback_summary(self, customer: Customer, interactions: list[Interaction]) -> str:
        days = self.priority_service.days_since_last(interactions)
        if not interactions:
            return f"{customer.name} has no recorded interactions yet."
        latest = interactions[0]
        wait = f"{days} days ago" if days is not None else "on an unknown date"
        return (
            f"{customer.name} is a {customer.status}. "
            f"Last contact was {wait} ({latest.type}). "
            "AI insights are unavailable until an API key is configured."
        )

    def _fallback_action(self, interactions: list[Interaction]) -> str:
        if not interactions:
            return "Make an introductory call and capture notes."
        return "Review the latest notes and send a short check-in."
