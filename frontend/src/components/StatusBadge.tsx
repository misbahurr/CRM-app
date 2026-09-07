import type { CustomerStatus } from '../types'

export function StatusBadge({ status }: { status: CustomerStatus }) {
  const label = status === 'prospect' ? 'Prospect' : 'Customer'
  const styles =
    status === 'prospect'
      ? 'bg-teal/10 text-teal-dark ring-teal/20'
      : 'bg-stone-100 text-ink ring-stone-200'
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ${styles}`}
    >
      {label}
    </span>
  )
}
