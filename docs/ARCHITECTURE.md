# Architecture (as built)

This is the developer map of the running system. Original intent lives in [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) and [BUILD_PLAN.md](BUILD_PLAN.md). Where they differ (Anthropic vs OpenAI-compatible, port numbers), **this file wins**.

```
Browser  →  Vite (5173, proxies /api)  →  FastAPI (8001)  →  MySQL (3307)
                                              └── AIService → OpenAI-compatible API
```

**Layering:** `Router → Service → Repository → SQLAlchemy model → MySQL`.

---

## 1. Class diagram

```mermaid
classDiagram
    class Customer {
        +str id
        +str name
        +str status
        +date created_at
    }
    class Contact {
        +str id
        +str customer_id
        +str name
        +str email
        +str role
    }
    class Interaction {
        +str id
        +str customer_id
        +str contact_id
        +str type
        +date occurred_at
        +str notes
    }
    class AIInsight {
        +str customer_id
        +str summary
        +str next_action
        +int priority_score
        +str priority_reason
        +datetime generated_at
    }

    class CustomerRepository {
        +get_all() List
        +get_by_id(id) Customer
        +get_with_relations(id) Customer
    }
    class InteractionRepository {
        +get_by_customer(customer_id) List
        +get_recent(customer_id, limit) List
    }
    class AIInsightRepository {
        +get_by_customer(customer_id) AIInsight
        +upsert(...) AIInsight
    }

    class AIService {
        -client OpenAI
        +enabled bool
        +generate_summary(interactions) str
        +generate_next_action(summary, interactions) NextActionResult
        +score_priority(customer, interactions) PriorityResult
    }
    class PriorityService {
        -ai_service AIService
        +recency_score(interactions) int
        +days_since_last(interactions) int
        +compute(customer, interactions) PriorityResult
    }
    class CustomerService {
        +list_customers_with_priority() List
        +get_customer_detail(id) CustomerDetailOut
        +get_or_generate_insights(id) InsightOut
        +refresh_insights(id) InsightOut
    }

    class CustomersRouter {
        +GET /api/customers
        +GET /api/customers/id
        +GET /api/customers/id/insights
        +POST /api/customers/id/insights/refresh
    }
    class InteractionsRouter {
        +GET /api/interactions
    }

    Customer "1" --> "many" Contact
    Customer "1" --> "many" Interaction
    Contact "1" --> "many" Interaction
    Customer "1" --> "0..1" AIInsight

    CustomersRouter --> CustomerService
    InteractionsRouter --> InteractionRepository
    CustomerService --> CustomerRepository
    CustomerService --> InteractionRepository
    CustomerService --> AIInsightRepository
    CustomerService --> PriorityService
    PriorityService --> AIService
```

| Module | Path |
|---|---|
| Models | `backend/app/models/` |
| Repositories | `backend/app/repositories/` |
| CustomerService | `backend/app/services/customer_service.py` |
| PriorityService | `backend/app/services/priority_service.py` |
| AIService | `backend/app/services/ai_service.py` |
| Routers | `backend/app/routers/customers.py`, `interactions.py` |

`PriorityService.compute()`: `score = round(0.4 * recency + 0.6 * ai)`. Recency is days since last interaction scaled to 0–100 (90 days = 100). If the model is off or errors, the feed still returns recency-only scores.

`AIService` is the only place that constructs the OpenAI client. `sk-or-` keys use `https://openrouter.ai/api/v1` unless `OPENAI_BASE_URL` is set.

---

## 2. Data model

```mermaid
erDiagram
    CUSTOMERS ||--o{ CONTACTS : has
    CUSTOMERS ||--o{ INTERACTIONS : has
    CONTACTS ||--o{ INTERACTIONS : participates_in
    CUSTOMERS ||--o| AI_INSIGHTS : caches

    CUSTOMERS {
        varchar id PK
        varchar name
        enum status
        date created_at
    }
    CONTACTS {
        varchar id PK
        varchar customer_id FK
        varchar name
        varchar email
        varchar role
    }
    INTERACTIONS {
        varchar id PK
        varchar customer_id FK
        varchar contact_id FK
        enum type
        date occurred_at
        text notes
    }
    AI_INSIGHTS {
        varchar customer_id PK_FK
        text summary
        text next_action
        int priority_score
        text priority_reason
        datetime generated_at
    }
```

`INTERACTIONS.notes` is what the model reads. `AI_INSIGHTS` is a cache (one row per customer), not a source of truth. Index: `interactions(customer_id, occurred_at)`.

Alembic: `backend/alembic/versions/001_initial_schema.py`. Seed: `backend/app/seed/data/*.csv`.

---

## 3. Sequence diagrams

### 3.1 Dashboard load

```mermaid
sequenceDiagram
    actor User
    participant FE as Dashboard
    participant API as CustomersRouter
    participant CS as CustomerService
    participant CR as CustomerRepository
    participant IR as InteractionRepository
    participant AIR as AIInsightRepository
    participant PS as PriorityService
    participant AI as AIService
    participant LLM as OpenAICompatibleAPI
    participant DB as MySQL

    User->>FE: Open /
    FE->>API: GET /api/customers
    API->>CS: list_customers_with_priority()
    CS->>CR: get_all()
    CR->>DB: SELECT customers
    DB-->>CS: customers

    loop each customer
        CS->>IR: get_by_customer(id)
        IR->>DB: SELECT interactions
        CS->>AIR: get_by_customer(id)
        AIR->>DB: SELECT ai_insights
        alt cache miss or recency fallback
            CS->>PS: compute(customer, interactions)
            alt AI enabled
                PS->>AI: score_priority()
                AI->>LLM: chat.completions JSON
                LLM-->>AI: score and reason
            else no key or error
                PS-->>CS: recency-only PriorityResult
            end
            CS->>AIR: upsert(priority fields)
        end
    end

    CS-->>FE: list sorted by priority_score desc
    FE-->>User: Ranked cards
```

### 3.2 Customer detail (summary + next action)

```mermaid
sequenceDiagram
    actor User
    participant FE as CustomerDetail
    participant API as CustomersRouter
    participant CS as CustomerService
    participant AIR as AIInsightRepository
    participant AI as AIService
    participant LLM as OpenAICompatibleAPI
    participant DB as MySQL

    User->>FE: Open /customers/id
    FE->>API: GET /api/customers/id
    API->>CS: get_customer_detail(id)
    CS-->>FE: contacts and timeline

    FE->>API: GET /api/customers/id/insights
    API->>CS: get_or_generate_insights(id)
    CS->>AIR: get_by_customer(id)
    AIR->>DB: SELECT ai_insights
    alt cache has a summary
        AIR-->>CS: AIInsight
    else cache miss
        CS->>AI: generate_summary()
        AI->>LLM: chat.completions
        CS->>AI: generate_next_action()
        AI->>LLM: chat.completions
        CS->>AIR: upsert()
        AIR->>DB: INSERT or UPDATE
    end
    CS-->>FE: InsightOut
    FE-->>User: AI panel plus timeline
```

### 3.3 Manual refresh

```mermaid
sequenceDiagram
    actor User
    participant FE as AISummaryPanel
    participant API as CustomersRouter
    participant CS as CustomerService
    participant AI as AIService
    participant LLM as OpenAICompatibleAPI
    participant AIR as AIInsightRepository
    participant DB as MySQL

    User->>FE: Refresh insights
    FE->>API: POST /api/customers/id/insights/refresh
    API->>CS: refresh_insights(id)
    CS->>AI: score_priority + summary + next_action
    AI->>LLM: up to 3 chat.completions
    LLM-->>AI: JSON results
    CS->>AIR: upsert(full insight)
    AIR->>DB: INSERT or UPDATE
    CS-->>FE: InsightOut
    FE-->>User: Updated panel
```

---

## 4. Frontend structure

```
App
├── Dashboard (/)
│   ├── attention count + color legend
│   ├── PriorityFilterBar
│   └── CustomerCard[]   (rank, status, priority, Why AI, last contact)
└── CustomerDetail (/customers/:id)
    ├── CustomerHeader   (name, status, contact cards)
    ├── AISummaryPanel   (summary, next action, copy draft, refresh)
    └── InteractionTimeline
```

| File | Role |
|---|---|
| `frontend/src/pages/Dashboard.tsx` | Fetch list, filters, counts |
| `frontend/src/pages/CustomerDetail.tsx` | Fetch detail + insights |
| `frontend/src/components/CustomerCard.tsx` | Display only |
| `frontend/src/components/AISummaryPanel.tsx` | AI UI + refresh |
| `frontend/src/components/InteractionTimeline.tsx` | Recorded events |
| `frontend/src/api/client.ts` | Typed `fetch` to `/api` |

---

## 5. Runtime

| Process | How | Port |
|---|---|---|
| MySQL | `docker compose up -d` | 3307 → 3306 in the container |
| FastAPI | `uvicorn app.main:app --reload --port 8001` | 8001 |
| Vite | `npm run dev` | 5173, proxy `/api` → 8001 |

Config is loaded from the repo-root `.env` (`backend/app/config.py`). Copy `.env.example` and set `OPENAI_API_KEY`.

---

## 6. Indexes and pagination

Indexes (Alembic `002_scale_indexes`):

| Index | Why |
|---|---|
| `customers(status)` | Prospect / customer filters |
| `customers(name)` | Stable sort tie-break |
| `ai_insights(priority_score)` | Order by urgency, “needs attention” count |
| `interactions(customer_id, occurred_at)` | Timeline + last-contact subquery |
| `interactions(contact_id)` | FK lookups |
| `contacts(email)` | Future search |

`GET /api/customers` is paginated (`limit` default 20, max 100, `offset`, `filter`). The feed with 12 practices still fits on one page — **Load more** only appears when `has_more` is true. Filter counts come from SQL aggregates, not the current page.

`GET /api/interactions` is paginated the same way (`limit` default 50). Detail still returns the full timeline for a single practice (typical volume is small).

