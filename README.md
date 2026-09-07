# AI-Powered Micro-CRM

Take-home: a small-business CRM for someone who sells an AI phone / scheduling product to dental practices. The user should spend almost no time on busywork and still know **who to talk to, why, what happened, and what to do next**.

## What I chose to build, and why

Four jobs from the brief, two screens:

| Brief | What shipped |
|---|---|
| Keep track of relationships and recent interactions | Practice detail: contacts + recorded timeline |
| Who may need attention | Priority feed, ranked by recency **and** AI judgment |
| Quick context | 2–3 sentence AI summary from the notes |
| Decide the next action | Suggested action + copyable draft |

I did **not** build a generic CRM (auth, edit forms, a chat box). Depth on the daily loop beat a longer feature list. AI is used only where notes beat a date sort: a happy customer who has been quiet is not urgent; a prospect silent after a proposal is.

The dataset is the **assignment sample** (12 practices, 15 contacts, 56 interactions).

| Screen | Route |
|---|---|
| Priority feed | `/` |
| Practice detail | `/customers/:id` |

**Developer docs:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/SYSTEM_DESIGN.md](docs/SYSTEM_DESIGN.md), [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md).

---

## Screenshots

Priority feed — ranked cards, AI “why”, last contact, filters:

![Priority feed](docs/screenshots/dashboard.png)

Practice detail — AI summary, next action, draft, timeline:

![Practice detail](docs/screenshots/detail.png)

---

## Key product and technical decisions

- **Feed, not a spreadsheet.** One ranked list. Color = urgency (60+ / 40–59 / under 40).
- **AI vs recorded data is labeled.** “Why (AI)” on cards; teal panel on detail; timeline is the source of truth.
- **Priority = 25% recency + 75% model.** Recency alone would punish quiet healthy accounts.
- **Cache in `ai_insights`.** Generate on miss or **Refresh**; not on every page load.
- **AI isolated** in `backend/app/services/ai_service.py` (OpenAI SDK; OpenRouter `sk-or-…` keys work).
- **Read-only UI.** Extra rows go through `python -m app.seed.add_entry`.
- **Pagination + indexes** so a larger book does not require a rewrite.

Stack: React / Vite / TypeScript / Tailwind, FastAPI, SQLAlchemy, Alembic, MySQL 8 (Docker, host port **3307**).

---

## Assumptions and simplifications

- One user, no auth.
- Sample CSVs are the book of record for the demo.
- OpenAI-compatible `gpt-4o-mini` (or OpenRouter) instead of a private model.
- MySQL on **3307**, API on **8001**, so they do not collide with other local services.
- Detail timeline is the full list for one practice (usually tens of rows, not thousands).

---

## What I would do next

- Persist a sent draft as a note.
- Batch insight generation in the background.
- A create/edit form if this became a daily tool.
- Light search.

---

## Quick start

Docker, Python 3.11+, Node 20+.

```bash
docker compose up -d
cp .env.example .env          # set OPENAI_API_KEY (OpenRouter sk-or-… is fine)

cd backend
python -m venv .venv && source .venv/bin/activate
pip install -e .
alembic upgrade head
python -m app.seed.seed_data
uvicorn app.main:app --reload --port 8001

# other terminal
cd frontend && npm install && npm run dev
```

- App: [http://127.0.0.1:5173](http://127.0.0.1:5173)
- API: [http://127.0.0.1:8001](http://127.0.0.1:8001) (`GET /health`, `/docs`)
- Vite proxies `/api` → port 8001

Without a key, the feed still runs on recency-only scores. After adding a key, reload the feed and use **Refresh insights** on a practice.

Reseed official sample: `FORCE_SEED=1 python -m app.seed.seed_data` from `backend/`.

Optional dump: [db/microcrm.sql](db/microcrm.sql) — [db/README.md](db/README.md). Refresh the dump after a reseed if you want it to match.

Add a row later:

```bash
cd backend
python -m app.seed.add_entry --file app/seed/data/example_entry.json
```

---

## How to use it

1. Open the feed. Highest urgency is at the top.
2. Filter: All / Needs attention / Prospects / Customers.
3. Open a card: AI summary + next action + draft; timeline underneath.
4. **Refresh insights** to call the model again.

Worth clicking after AI has run:

- **Parkview Dental Studio** — high intent, onboarding deadline
- **Northstar Dental Group** / **Lakeside Dental Care** — silent after proposal or pricing
- **Riverbend Orthodontics** — demo never booked
- **Willow Creek Dental** / **Oak & Pine** — satisfied, do not nag
- **Evergreen Dental Partners** — interested, notes say do not push before September planning

---

## How AI is used

| Job | When | Output |
|---|---|---|
| Priority | Feed load if no real score yet; also on refresh | `{ score, reason }` |
| Summary | Detail / refresh | 2–3 sentences |
| Next action | Detail / refresh | Action + optional draft |

Score: `round(0.25 * recency + 0.75 * ai)`. Cached per customer. Refresh is the only manual re-run.

---

## API

| Method | Route | Purpose |
|---|---|---|
| GET | `/health` | Liveness |
| GET | `/api/customers` | Page: `filter`, `limit` (default 20), `offset` → `{ items, total, has_more, counts }` |
| GET | `/api/customers/{id}` | Contacts + timeline |
| GET | `/api/customers/{id}/insights` | Cached or generated insight |
| POST | `/api/customers/{id}/insights/refresh` | Force regenerate |
| GET | `/api/interactions?customer_id=` | Page: `limit`, `offset` |

---

## Out of scope

- Auth / multi-user
- Create or edit in the UI
- Notifications
- A generic AI chat
