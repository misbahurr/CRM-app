import { useState } from 'react'
import { formatDate } from '../lib/format'
import type { Insight } from '../types'
import { PriorityBadge } from './PriorityBadge'

function SparkleIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-4 w-4 fill-teal" aria-hidden="true">
      <path d="M12 2.5 13.6 9l6.4 1.6-6.4 1.6L12 18.7 10.4 12.2 4 10.6 10.4 9z" />
    </svg>
  )
}

function isFallback(insight: Insight | null): boolean {
  if (!insight) return true
  const reason = insight.priority_reason ?? ''
  const summary = insight.summary ?? ''
  return (
    reason.startsWith('No AI score yet') ||
    summary.includes('AI insights are unavailable')
  )
}

export function AISummaryPanel({
  insight,
  loading,
  refreshing,
  onRefresh,
}: {
  insight: Insight | null
  loading: boolean
  refreshing: boolean
  onRefresh: () => void
}) {
  const [copied, setCopied] = useState(false)
  const fallback = isFallback(insight)

  async function copyDraft() {
    if (!insight?.drafted_message) return
    await navigator.clipboard.writeText(insight.drafted_message)
    setCopied(true)
    window.setTimeout(() => setCopied(false), 1500)
  }

  if (loading) {
    return (
      <section className="rounded-2xl border border-teal/25 bg-gradient-to-br from-teal/10 to-card p-5">
        <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-teal-dark">
          <SparkleIcon />
          Generating AI insight…
        </div>
        <p className="mb-3 text-sm text-muted">
          Reading the interaction notes — this is slower the first time, then cached.
        </p>
        <div className="space-y-2">
          <div className="h-4 w-full animate-pulse rounded bg-teal/10" />
          <div className="h-4 w-5/6 animate-pulse rounded bg-teal/10" />
          <div className="h-4 w-2/3 animate-pulse rounded bg-teal/10" />
        </div>
      </section>
    )
  }

  return (
      <section className="rounded-2xl border border-teal/25 bg-gradient-to-br from-teal/10 to-card p-5">
      <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
        <div>
          <div className="flex items-center gap-2 text-sm font-semibold text-teal-dark">
            <SparkleIcon />
            AI judgment
            <span className="rounded-full bg-white/80 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-teal-dark ring-1 ring-teal/20">
              Generated
            </span>
          </div>
          <p className="mt-1 text-sm text-muted">
            Suggestion from notes — not a recorded fact.
            {insight?.generated_at
              ? ` Updated ${formatDate(insight.generated_at)}.`
              : null}
          </p>
        </div>
        <button
          type="button"
          onClick={onRefresh}
          disabled={refreshing}
          className="rounded-full border border-teal/30 bg-white px-3 py-1.5 text-xs font-semibold text-teal-dark hover:bg-teal/5 disabled:opacity-60"
        >
          {refreshing ? 'Refreshing…' : 'Refresh insights'}
        </button>
      </div>

      {fallback ? (
        <p className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-watch">
          Showing a recency fallback. Add a valid OpenAI key and refresh to get a
          real summary.
        </p>
      ) : null}

      {insight?.priority_score != null ? (
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <PriorityBadge score={insight.priority_score} />
          <p className="text-sm text-ink">{insight.priority_reason}</p>
        </div>
      ) : null}

      <div>
        <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-teal-dark">
          Where things stand
        </p>
        <p className="mt-1 text-[16px] leading-relaxed text-ink">
          {insight?.summary || 'No summary yet.'}
        </p>
      </div>

      <div className="mt-4 rounded-xl bg-white/80 p-4 ring-1 ring-teal/10">
        <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-teal-dark">
          Suggested next action
        </p>
        <p className="mt-1 text-[15px] leading-relaxed text-ink">
          {insight?.next_action || 'No action suggested yet.'}
        </p>
        {insight?.drafted_message ? (
          <div className="mt-3 border-t border-line pt-3">
            <div className="mb-1.5 flex items-center justify-between">
              <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-muted">
                Draft you can send
              </p>
              <button
                type="button"
                onClick={() => void copyDraft()}
                className="text-xs font-semibold text-teal-dark"
              >
                {copied ? 'Copied' : 'Copy'}
              </button>
            </div>
            <p className="whitespace-pre-wrap text-sm leading-relaxed text-ink/90">
              {insight.drafted_message}
            </p>
          </div>
        ) : null}
      </div>
    </section>
  )
}
