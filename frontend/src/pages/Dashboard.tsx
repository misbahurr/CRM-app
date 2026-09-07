import { useEffect, useState } from 'react'
import { PAGE_SIZE, api } from '../api/client'
import { CustomerCard } from '../components/CustomerCard'
import { LoadingSkeleton } from '../components/LoadingSkeleton'
import { PriorityFilterBar } from '../components/PriorityFilterBar'
import type { CustomerSummary, FilterCounts, PriorityFilter } from '../types'

const EMPTY_COUNTS: FilterCounts = {
  all: 0,
  attention: 0,
  prospects: 0,
  customers: 0,
}

export function Dashboard() {
  const [customers, setCustomers] = useState<CustomerSummary[]>([])
  const [filter, setFilter] = useState<PriorityFilter>('all')
  const [counts, setCounts] = useState<FilterCounts>(EMPTY_COUNTS)
  const [total, setTotal] = useState(0)
  const [hasMore, setHasMore] = useState(false)
  const [loading, setLoading] = useState(true)
  const [loadingMore, setLoadingMore] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setError(null)
    api
      .listCustomers({ filter, limit: PAGE_SIZE, offset: 0 })
      .then((page) => {
        if (cancelled) return
        setCustomers(page.items)
        setCounts(page.counts)
        setTotal(page.total)
        setHasMore(page.has_more)
      })
      .catch((err: unknown) => {
        if (!cancelled) setError(err instanceof Error ? err.message : 'Failed to load')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [filter])

  async function loadMore() {
    setLoadingMore(true)
    try {
      const page = await api.listCustomers({
        filter,
        limit: PAGE_SIZE,
        offset: customers.length,
      })
      setCustomers((current) => {
        const seen = new Set(current.map((row) => row.id))
        return [...current, ...page.items.filter((row) => !seen.has(row.id))]
      })
      setCounts(page.counts)
      setTotal(page.total)
      setHasMore(page.has_more)
    } finally {
      setLoadingMore(false)
    }
  }

  const usingFallback = customers.some((c) =>
    c.priority_reason.startsWith('No AI score yet'),
  )

  return (
    <div>
      <h1 className="font-heading text-3xl text-ink">Priority feed</h1>
      <p className="mt-1 text-[16px] text-muted">
        Ranked by recency plus AI judgment — not just days since last contact.
      </p>

      {!loading && !error ? (
        <p className="mt-3 text-sm text-ink">
          <span className="font-semibold text-urgent">{counts.attention}</span>
          {counts.attention === 1
            ? ' practice needs attention'
            : ' practices need attention'}
          <span className="text-muted">
            {' '}
            · {counts.all} on the books
          </span>
        </p>
      ) : null}

      {usingFallback ? (
        <p className="mt-3 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-watch">
          Scores are recency-only until OpenAI is configured. Quiet customers can
          look urgent until a real AI pass runs.
        </p>
      ) : null}

      <div className="mt-5 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
        <span>
          <span className="mr-1 inline-block h-2 w-2 rounded-full bg-urgent" />
          Needs attention (60+)
        </span>
        <span>
          <span className="mr-1 inline-block h-2 w-2 rounded-full bg-watch" />
          Check in soon (40–59)
        </span>
        <span>
          <span className="mr-1 inline-block h-2 w-2 rounded-full bg-healthy" />
          Healthy (under 40)
        </span>
      </div>

      <div className="mt-4">
        <PriorityFilterBar value={filter} onChange={setFilter} counts={counts} />
      </div>

      <div className="mt-5 space-y-3">
        {loading ? <LoadingSkeleton /> : null}
        {error ? (
          <p className="rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-urgent">
            Could not load the feed. Is the API running on port 8001?
          </p>
        ) : null}
        {!loading && !error && customers.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-line px-4 py-10 text-center text-sm text-muted">
            No practices match this filter.
          </p>
        ) : null}
        {customers.map((customer, index) => (
          <CustomerCard key={customer.id} customer={customer} rank={index + 1} />
        ))}
        {hasMore ? (
          <button
            type="button"
            onClick={() => void loadMore()}
            disabled={loadingMore}
            className="w-full rounded-2xl border border-line bg-card py-3 text-sm font-medium text-teal-dark hover:border-teal/40 disabled:opacity-60"
          >
            {loadingMore
              ? 'Loading…'
              : `Load more (${customers.length} of ${total})`}
          </button>
        ) : null}
      </div>
    </div>
  )
}
