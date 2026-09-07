import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client'
import { CustomerCard } from '../components/CustomerCard'
import { LoadingSkeleton } from '../components/LoadingSkeleton'
import { PriorityFilterBar } from '../components/PriorityFilterBar'
import type { CustomerSummary, PriorityFilter } from '../types'

export function Dashboard() {
  const [customers, setCustomers] = useState<CustomerSummary[]>([])
  const [filter, setFilter] = useState<PriorityFilter>('all')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    api
      .listCustomers()
      .then((rows) => {
        if (!cancelled) setCustomers(rows)
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
  }, [])

  const counts = useMemo(
    () => ({
      all: customers.length,
      attention: customers.filter((c) => c.priority_score >= 70).length,
      prospects: customers.filter((c) => c.status === 'prospect').length,
      customers: customers.filter((c) => c.status === 'customer').length,
    }),
    [customers],
  )

  const visible = useMemo(() => {
    return customers.filter((customer) => {
      if (filter === 'attention') return customer.priority_score >= 70
      if (filter === 'prospects') return customer.status === 'prospect'
      if (filter === 'customers') return customer.status === 'customer'
      return true
    })
  }, [customers, filter])

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
          Needs attention (70+)
        </span>
        <span>
          <span className="mr-1 inline-block h-2 w-2 rounded-full bg-watch" />
          Check in soon (40–69)
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
        {!loading && !error && visible.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-line px-4 py-10 text-center text-sm text-muted">
            No practices match this filter.
          </p>
        ) : null}
        {visible.map((customer, index) => (
          <CustomerCard key={customer.id} customer={customer} rank={index + 1} />
        ))}
      </div>
    </div>
  )
}
