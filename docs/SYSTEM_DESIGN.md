# AI-Powered Micro-CRM — System Design

Companion to [BUILD_PLAN.md](BUILD_PLAN.md). Original design: ERD, backend classes, sequences, frontend.

**As built:** see [ARCHITECTURE.md](ARCHITECTURE.md) — class diagram, sequences, and file map matching the code. Differences from this draft: OpenAI-compatible SDK (OpenAI or OpenRouter), MySQL on host **3307**, API on **8001**, insights live on the customers router (no separate `ai.py`).

> **AI provider:** `ai_service.py` wraps the OpenAI SDK (`gpt-4o-mini`). OpenRouter keys (`sk-or-…`) work via `OPENAI_BASE_URL` / auto-detect. Everything else is provider-agnostic.

---

## 1. Database Architecture (ERD)

```mermaid
erDiagram
    CUSTOMERS ||--o{ CONTACTS : has
    CUSTOMERS ||--o{ INTERACTIONS : has
    CONTACTS ||--o{ INTERACTIONS : participates_in
    CUSTOMERS ||--o| AI_INSIGHTS : has

    CUSTOMERS {
        varchar id PK
        varchar name
        enum status "prospect | customer"
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
        enum type "email | call | meeting | note"
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

**Design notes:**
- `AI_INSIGHTS` is a cache table, one row per customer, regenerated on demand — keeps AI calls off the hot path of every page load.
- `INTERACTIONS.notes` is the richest field — it's the raw input the AI service reads to generate summaries/priority. Treat it as the "source of truth" the AI reasons over.
- Indexes worth adding: `interactions(customer_id, occurred_at DESC)` since the dashboard and timeline both query "most recent interaction per customer."

---

## 2. Backend Class Diagram

```mermaid
classDiagram
    class Customer {
        +str id
        +str name
        +str status
        +date created_at
        +List~Contact~ contacts
        +List~Interaction~ interactions
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
        +get_all() List~Customer~
        +get_by_id(id) Customer
        +get_with_relations(id) Customer
    }

    class InteractionRepository {
        +get_by_customer(customer_id) List~Interaction~
        +get_recent(customer_id, limit) List~Interaction~
    }

    class AIInsightRepository {
        +get_by_customer(customer_id) AIInsight
        +upsert(customer_id, insight) AIInsight
    }

    class AIService {
        -client: OpenAIClient
        +generate_summary(interactions) str
        +generate_next_action(summary, interactions) str
        +score_priority(customer, interactions) PriorityResult
    }

    class PriorityService {
        -ai_service: AIService
        +compute(customer, interactions) PriorityResult
        -recency_score(interactions) int
    }

    class PriorityResult {
        +int score
        +str reason
    }

    class CustomerService {
        -customer_repo: CustomerRepository
        -interaction_repo: InteractionRepository
        -insight_repo: AIInsightRepository
        -priority_service: PriorityService
        +list_customers_with_priority() List~CustomerSummaryDTO~
        +get_customer_detail(id) CustomerDetailDTO
        +get_or_generate_insights(id) AIInsight
        +refresh_insights(id) AIInsight
    }

    class CustomersRouter {
        +GET /api/customers
        +GET /api/customers/id
        +GET /api/customers/id/insights
        +POST /api/customers/id/insights/refresh
    }

    Customer "1" --> "many" Contact
    Customer "1" --> "many" Interaction
    Customer "1" --> "0..1" AIInsight
    CustomerService --> CustomerRepository
    CustomerService --> InteractionRepository
    CustomerService --> AIInsightRepository
    CustomerService --> PriorityService
    PriorityService --> AIService
    CustomersRouter --> CustomerService
```

**Layering:** `Router → Service → Repository → DB Model`. Keep AI calls isolated inside `AIService` so it's the only class that knows about the OpenAI SDK — makes it trivial to swap providers or mock in tests.

---

## 3. Sequence Diagrams

### 3.1 Dashboard load (prioritized customer list)

```mermaid
sequenceDiagram
    actor User
    participant FE as React Dashboard
    participant API as CustomersRouter
    participant CS as CustomerService
    participant CR as CustomerRepository
    participant IR as InteractionRepository
    participant AIR as AIInsightRepository
    participant DB as MySQL

    User->>FE: Open dashboard
    FE->>API: GET /api/customers
    API->>CS: list_customers_with_priority()
    CS->>CR: get_all()
    CR->>DB: SELECT * FROM customers
    DB-->>CR: rows
    CR-->>CS: List~Customer~

    loop for each customer
        CS->>AIR: get_by_customer(id)
        AIR->>DB: SELECT * FROM ai_insights WHERE customer_id=?
        DB-->>AIR: cached insight (or null)
        AIR-->>CS: AIInsight | null
        alt no cached insight
            CS->>IR: get_by_customer(id)
            IR->>DB: SELECT * FROM interactions WHERE customer_id=?
            DB-->>IR: rows
            IR-->>CS: List~Interaction~
            CS->>CS: priority_service.compute() [calls AI once]
            CS->>AIR: upsert(customer_id, insight)
        end
    end

    CS-->>API: List~CustomerSummaryDTO~ (sorted by priority_score desc)
    API-->>FE: 200 JSON
    FE-->>User: Render prioritized cards
```

### 3.2 Customer detail view (AI summary + next action)

```mermaid
sequenceDiagram
    actor User
    participant FE as CustomerDetail Page
    participant API as CustomersRouter
    participant CS as CustomerService
    participant AIR as AIInsightRepository
    participant AI as AIService
    participant OpenAI as OpenAI API
    participant DB as MySQL

    User->>FE: Click customer card
    FE->>API: GET /api/customers/{id}
    API->>CS: get_customer_detail(id)
    CS-->>API: CustomerDetailDTO (contacts + timeline)
    API-->>FE: 200 JSON
    FE->>API: GET /api/customers/{id}/insights
    API->>CS: get_or_generate_insights(id)
    CS->>AIR: get_by_customer(id)
    AIR->>DB: SELECT * FROM ai_insights WHERE customer_id=?
    DB-->>AIR: cached row (or null)
    alt cache hit
        AIR-->>CS: AIInsight
    else cache miss
        CS->>AI: generate_summary(interactions)
        AI->>OpenAI: chat.completions.create(...)
        OpenAI-->>AI: summary text
        CS->>AI: generate_next_action(summary, interactions)
        AI->>OpenAI: chat.completions.create(...)
        OpenAI-->>AI: next_action text
        CS->>AIR: upsert(customer_id, insight)
        AIR->>DB: INSERT/UPDATE ai_insights
        AIR-->>CS: AIInsight
    end
    CS-->>API: AIInsight
    API-->>FE: 200 JSON
    FE-->>User: Render summary + next action panel
```

### 3.3 Manual insight refresh

```mermaid
sequenceDiagram
    actor User
    participant FE as AISummaryPanel
    participant API as CustomersRouter
    participant CS as CustomerService
    participant AI as AIService
    participant OpenAI as OpenAI API
    participant AIR as AIInsightRepository

    User->>FE: Click "Refresh insights"
    FE->>API: POST /api/customers/{id}/insights/refresh
    API->>CS: refresh_insights(id)
    CS->>AI: generate_summary() + generate_next_action() + score_priority()
    AI->>OpenAI: 3x chat.completions.create(...)
    OpenAI-->>AI: results
    CS->>AIR: upsert(customer_id, new insight)
    CS-->>API: AIInsight
    API-->>FE: 200 JSON (updated)
    FE-->>User: Re-render with fresh summary/action
```

---

## 4. Frontend Design

### 4.1 Page structure

```
App
├── Dashboard (/)
│   ├── PriorityFilterBar        (all / needs attention / prospects / customers)
│   ├── CustomerCard[]
│   │   ├── StatusBadge          (prospect / customer)
│   │   ├── PriorityBadge        (color-coded: red/amber/green)
│   │   └── "why" one-liner      (AI priority_reason)
│   └── LoadingSkeleton
│
└── CustomerDetail (/customers/:id)
    ├── CustomerHeader           (name, status, contacts list)
    ├── AISummaryPanel
    │   ├── Summary text
    │   ├── SuggestedNextAction  (with "copy" button for drafted message)
    │   └── RefreshButton
    └── InteractionTimeline
        └── TimelineItem[]        (icon per type: email/call/meeting/note)
```

### 4.2 Visual design direction

- **Layout:** Dashboard as a single-column priority feed (not a dense table) — reinforces "here's who needs your attention today," not "here's a spreadsheet."
- **Priority color coding:**
  - 🔴 Red — high urgency (e.g., stalled post-proposal, high-intent prospect gone quiet)
  - 🟡 Amber — worth a check-in soon
  - 🟢 Green — quiet but healthy (satisfied customer, no action needed)
- **Typography:** one clear heading font + one body font, generous whitespace — avoid a cluttered "enterprise CRM" feel since the audience is a small business owner, not a sales ops team.
- **AI content visually distinct:** give the summary/next-action panel a subtle accent background or icon (e.g., a small sparkle icon) so it reads as "AI-generated insight" vs. raw data — builds trust by being transparent about what's AI vs. what's fact from the DB.
- **Empty/loading states:** since AI calls add latency, show a skeleton loader on first insight generation, with cached (instant) loads afterward.

### 4.3 Component responsibility

| Component | Responsibility |
|---|---|
| `Dashboard.tsx` | Fetch `/api/customers`, hold filter state, render list |
| `CustomerCard.tsx` | Pure display: name, status, priority badge, reason — no logic |
| `CustomerDetail.tsx` | Fetch detail + insights, orchestrate child components |
| `AISummaryPanel.tsx` | Display summary/next-action, handle refresh button + loading state |
| `InteractionTimeline.tsx` | Render sorted interaction list with type icons |
| `api/client.ts` | Single fetch wrapper — base URL, error handling, typed responses |

---

## 5. How These Pieces Fit the Assignment's Evaluation Criteria

- **Where AI adds value** is explicit and isolated (`AIService`) — easy to point to in your README as a deliberate architectural choice, not AI sprinkled everywhere.
- **Priority logic** combines a computed signal (recency) with an AI-reasoned signal (context-aware urgency) — this is the "smart" part worth highlighting.
- **Caching (`ai_insights` table)** shows awareness of cost/latency tradeoffs, which is a strong signal in a take-home for an AI product role.
