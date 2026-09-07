import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { api } from '../api/client'
import { AISummaryPanel } from '../components/AISummaryPanel'
import { CustomerHeader } from '../components/CustomerHeader'
import { InteractionTimeline } from '../components/InteractionTimeline'
import { LoadingSkeleton } from '../components/LoadingSkeleton'
import type { CustomerDetail as CustomerDetailType, Insight } from '../types'

export function CustomerDetail() {
  const { id } = useParams<{ id: string }>()
  const [customer, setCustomer] = useState<CustomerDetailType | null>(null)
  const [insight, setInsight] = useState<Insight | null>(null)
  const [loading, setLoading] = useState(true)
  const [insightLoading, setInsightLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    let cancelled = false
    setLoading(true)
    setInsightLoading(true)
    setError(null)

    api
      .getCustomer(id)
      .then((detail) => {
        if (!cancelled) setCustomer(detail)
      })
      .catch((err: unknown) => {
        if (!cancelled) setError(err instanceof Error ? err.message : 'Not found')
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })

    api
      .getInsights(id)
      .then((row) => {
        if (!cancelled) setInsight(row)
      })
      .catch(() => {
        if (!cancelled) setInsight(null)
      })
      .finally(() => {
        if (!cancelled) setInsightLoading(false)
      })

    return () => {
      cancelled = true
    }
  }, [id])

  async function refresh() {
    if (!id) return
    setRefreshing(true)
    try {
      const row = await api.refreshInsights(id)
      setInsight(row)
    } finally {
      setRefreshing(false)
    }
  }

  if (loading) return <LoadingSkeleton rows={3} />
  if (error || !customer) {
    return (
      <div>
        <p className="text-urgent">{error || 'Practice not found.'}</p>
        <Link to="/" className="mt-3 inline-block text-sm font-medium text-teal-dark">
          Back to priority feed
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <Link
        to="/"
        className="inline-flex text-sm font-medium text-teal-dark no-underline hover:underline"
      >
        ← Priority feed
      </Link>
      <CustomerHeader customer={customer} />
      <AISummaryPanel
        insight={insight}
        loading={insightLoading}
        refreshing={refreshing}
        onRefresh={() => void refresh()}
      />
      <section>
        <h2 className="mb-4 font-heading text-xl text-ink">Recorded timeline</h2>
        <InteractionTimeline interactions={customer.interactions} />
      </section>
    </div>
  )
}
