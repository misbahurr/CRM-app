import type { PriorityFilter } from '../types'

type Counts = Record<PriorityFilter, number>

const FILTERS: { id: PriorityFilter; label: string }[] = [
  { id: 'all', label: 'All' },
  { id: 'attention', label: 'Needs attention' },
  { id: 'prospects', label: 'Prospects' },
  { id: 'customers', label: 'Customers' },
]

export function PriorityFilterBar({
  value,
  onChange,
  counts,
}: {
  value: PriorityFilter
  onChange: (next: PriorityFilter) => void
  counts: Counts
}) {
  return (
    <div className="flex flex-wrap gap-2">
      {FILTERS.map((filter) => {
        const active = filter.id === value
        return (
          <button
            key={filter.id}
            type="button"
            onClick={() => onChange(filter.id)}
            className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm transition ${
              active
                ? 'border-teal bg-teal text-white'
                : 'border-line bg-card text-muted hover:border-teal/40 hover:text-ink'
            }`}
          >
            {filter.label}
            <span
              className={`tabular-nums text-xs ${active ? 'text-white/80' : 'text-muted'}`}
            >
              {counts[filter.id]}
            </span>
          </button>
        )
      })}
    </div>
  )
}
