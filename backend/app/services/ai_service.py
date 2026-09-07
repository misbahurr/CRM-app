from __future__ import annotations

import json
from dataclasses import dataclass

from openai import OpenAI

from app.config import Settings, get_settings
from app.models.customer import Customer
from app.models.interaction import Interaction


@dataclass
class PriorityResult:
    score: int
    reason: str


@dataclass
class NextActionResult:
    action: str
    drafted_message: str | None = None


class AIService:
    def __init__(self, settings: Settings | None = None) -> None:
        self.settings = settings or get_settings()
        key = (self.settings.openai_api_key or "").strip()
        self._enabled = bool(key) and not key.startswith("sk-...")
        base_url = (self.settings.openai_base_url or "").strip()
        if not base_url and key.startswith("sk-or-"):
            base_url = "https://openrouter.ai/api/v1"
        if self._enabled:
            kwargs: dict = {"api_key": key}
            if base_url:
                kwargs["base_url"] = base_url
            self._client = OpenAI(**kwargs)
        else:
            self._client = None

    @property
    def enabled(self) -> bool:
        return self._enabled and self._client is not None

    def generate_summary(self, interactions: list[Interaction]) -> str:
        payload = self._timeline(interactions)
        data = self._complete(
            system=(
                "You are a CRM analyst for a small-business owner who sells an AI phone, "
                "scheduling, and call-summary product to dental practices. "
                "Return JSON only: {\"summary\": \"2-3 sentences on where things stand\"}."
            ),
            user=f"Interaction timeline (newest first):\n{payload}",
        )
        return str(data.get("summary") or "").strip()

    def generate_next_action(
        self, summary: str, interactions: list[Interaction]
    ) -> NextActionResult:
        payload = self._timeline(interactions)
        data = self._complete(
            system=(
                "You are a practical CRM coach for a small-business owner selling AI answering "
                "and scheduling to dental practices. "
                "Honor explicit notes like 'do not push' or 'no additional follow-up'. "
                "Return JSON only: "
                '{"action": "one concrete next step", "drafted_message": "optional short email/SMS draft or null"}.'
            ),
            user=f"Summary:\n{summary}\n\nTimeline (newest first):\n{payload}",
        )
        draft = data.get("drafted_message")
        if isinstance(draft, str):
            draft = draft.strip() or None
        else:
            draft = None
        return NextActionResult(
            action=str(data.get("action") or "Review the latest notes and decide a follow-up.").strip(),
            drafted_message=draft,
        )

    def score_priority(
        self, customer: Customer, interactions: list[Interaction]
    ) -> PriorityResult:
        payload = self._timeline(interactions)
        last = interactions[0].occurred_at.isoformat() if interactions else "never"
        data = self._complete(
            system=(
                "You score CRM urgency for a small-business owner selling an AI phone/scheduling "
                "product to dental practices. "
                "A satisfied customer who has been quiet for months is NOT urgent. "
                "A prospect who went cold after a proposal, pricing, or an unbooked demo IS urgent. "
                "A high-intent prospect with an onboarding deadline is urgent even if last contact was recent. "
                "If notes say not to push or that no follow-up is required, score that as healthy/low. "
                "Score 0-100 where 70+ needs attention now, 40-69 worth a check-in, under 40 healthy/quiet. "
                "Return JSON only: {\"score\": int, \"reason\": \"one-line why\"}."
            ),
            user=(
                f"Customer: {customer.name} ({customer.status}), last contact: {last}.\n"
                f"Timeline (newest first):\n{payload}"
            ),
        )
        try:
            score = int(data.get("score", 50))
        except (TypeError, ValueError):
            score = 50
        score = max(0, min(100, score))
        reason = str(data.get("reason") or "Unable to judge urgency from notes.").strip()
        return PriorityResult(score=score, reason=reason)

    def _complete(self, system: str, user: str) -> dict:
        if not self._client:
            raise RuntimeError("OpenAI client is not configured")
        response = self._client.chat.completions.create(
            model=self.settings.openai_model,
            response_format={"type": "json_object"},
            temperature=0.2,
            messages=[
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        )
        content = response.choices[0].message.content or "{}"
        try:
            parsed = json.loads(content)
        except json.JSONDecodeError:
            return {}
        return parsed if isinstance(parsed, dict) else {}

    @staticmethod
    def _timeline(interactions: list[Interaction]) -> str:
        if not interactions:
            return "(no interactions)"
        lines: list[str] = []
        for item in interactions:
            contact = item.contact.name if item.contact else item.contact_id
            notes = (item.notes or "").strip()
            lines.append(
                f"- {item.occurred_at.isoformat()} [{item.type}] {contact}: {notes}"
            )
        return "\n".join(lines)
