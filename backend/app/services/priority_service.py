from __future__ import annotations

from datetime import date

from app.models.customer import Customer
from app.models.interaction import Interaction
from app.services.ai_service import AIService, PriorityResult


class PriorityService:
    def __init__(self, ai_service: AIService | None = None) -> None:
        self.ai_service = ai_service or AIService()

    def recency_score(self, interactions: list[Interaction]) -> int:
        days = self.days_since_last(interactions)
        if days is None:
            return 100
        return min(100, round(days * 100 / 90))

    def days_since_last(self, interactions: list[Interaction]) -> int | None:
        if not interactions:
            return None
        last = max(item.occurred_at for item in interactions)
        return max(0, (date.today() - last).days)

    def compute(
        self, customer: Customer, interactions: list[Interaction]
    ) -> PriorityResult:
        recency = self.recency_score(interactions)
        days = self.days_since_last(interactions)
        fallback_reason = (
            "No interactions on record — needs a first conversation."
            if days is None
            else f"Last contact {days} day{'s' if days != 1 else ''} ago."
        )
        if not self.ai_service.enabled:
            prefix = "No AI score yet — "
            return PriorityResult(
                score=recency,
                reason=prefix + fallback_reason[0].lower() + fallback_reason[1:]
                if days is not None
                else prefix + fallback_reason,
            )
        try:
            ai = self.ai_service.score_priority(customer, interactions)
        except Exception:
            return PriorityResult(score=recency, reason=fallback_reason)
        combined = round(0.4 * recency + 0.6 * ai.score)
        return PriorityResult(score=max(0, min(100, combined)), reason=ai.reason)
