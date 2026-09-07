import { Link } from 'react-router-dom'
import { daysLabel, formatDate } from '../lib/format'
import type { CustomerSummary } from '../types'
import { priorityLevel } from '../types'
import { PriorityBadge } from './PriorityBadge'
import { StatusBadge } from './StatusBadge'

const ACCENT: Record<ReturnType<typeof priorityLevel>, string> = {
  high: 'bg-urgent',
  medium: 'bg-watch',
  low: 'bg-healthy',
}

export function CustomerCard({
  customer,
  rank,
}: {
  customer: CustomerSummary
  rank: number
}) {
  const level = priorityLevel(customer.priority_score)

  return (
    <Link
      to={`/customers/${customer.id}`}
      className="group block rounded-2xl border border-line bg-card no-underline shadow-[0_1px_0_rgba(28,25,23,0.04)] transition hover:-translate-y-0.5 hover:border-teal/30 hover:shadow-md"
    >
      <div className="flex">
        <span className={`w-1.5 shrink-0 rounded-l-2xl ${ACCENT[level]}`} />
        <div className="min-w-0 flex-1 p-5">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-muted">
                #{rank}
              </p>
              <h2 className="font-heading mt-0.5 text-xl text-ink group-hover:text-teal-dark">
                {customer.name}
              </h2>
            </div>
            <div className="flex flex-wrap justify-end gap-1.5">
              <StatusBadge status={customer.status} />
              <PriorityBadge score={customer.priority_score} />
            </div>
          </div>

          <div className="mt-3 rounded-xl bg-teal/5 px-3 py-2.5">
            <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-teal-dark">
              Why (AI)
            </p>
            <p className="mt-1 text-[15px] leading-snug text-ink">
              {customer.priority_reason}
            </p>
          </div>

          <p className="mt-3 text-sm text-muted">
            Last recorded contact{' '}
            <span className="font-medium text-ink">
              {formatDate(customer.last_interaction_at)}
            </span>
            <span> · {daysLabel(customer.days_since_last)}</span>
          </p>
        </div>
      </div>
    </Link>
  )
}
