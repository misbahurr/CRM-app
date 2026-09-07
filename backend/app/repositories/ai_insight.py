from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.models.ai_insight import AIInsight


class AIInsightRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_customer(self, customer_id: str) -> AIInsight | None:
        return self.db.get(AIInsight, customer_id)

    def upsert(
        self,
        customer_id: str,
        *,
        summary: str | None,
        next_action: str | None,
        priority_score: int | None,
        priority_reason: str | None,
        generated_at: datetime | None = None,
    ) -> AIInsight:
        row = self.get_by_customer(customer_id)
        stamp = generated_at or datetime.now(UTC).replace(tzinfo=None)
        if row is None:
            row = AIInsight(customer_id=customer_id)
            self.db.add(row)
        row.summary = summary
        row.next_action = next_action
        row.priority_score = priority_score
        row.priority_reason = priority_reason
        row.generated_at = stamp
        self.db.commit()
        self.db.refresh(row)
        return row
