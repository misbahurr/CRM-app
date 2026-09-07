import type { Interaction, InteractionType } from '../types'
import { formatDate } from '../lib/format'

const META: Record<
  InteractionType,
  { label: string; className: string }
> = {
  email: { label: 'Email', className: 'bg-sky-50 text-sky-800 ring-sky-100' },
  call: { label: 'Call', className: 'bg-violet-50 text-violet-800 ring-violet-100' },
  meeting: {
    label: 'Meeting',
    className: 'bg-teal/10 text-teal-dark ring-teal/15',
  },
  note: { label: 'Note', className: 'bg-stone-100 text-ink ring-stone-200' },
}

export function InteractionTimeline({
  interactions,
}: {
  interactions: Interaction[]
}) {
  if (interactions.length === 0) {
    return (
      <p className="rounded-2xl border border-dashed border-line px-4 py-8 text-center text-sm text-muted">
        No interactions recorded yet.
      </p>
    )
  }

  return (
    <ol>
      {interactions.map((item, index) => {
        const meta = META[item.type] ?? META.note
        return (
          <li key={item.id} className="flex gap-4">
            <div className="flex w-8 flex-col items-center">
              <span className="mt-1 h-2.5 w-2.5 rounded-full bg-teal ring-4 ring-teal/15" />
              {index < interactions.length - 1 ? (
                <span className="w-px flex-1 bg-line" />
              ) : (
                <span className="h-2" />
              )}
            </div>
            <div className="min-w-0 flex-1 pb-6">
              <div className="flex flex-wrap items-center gap-2">
                <span
                  className={`rounded-full px-2 py-0.5 text-xs font-semibold ring-1 ${meta.className}`}
                >
                  {meta.label}
                </span>
                <span className="text-sm font-medium text-ink">
                  {formatDate(item.occurred_at)}
                </span>
                {item.contact_name ? (
                  <span className="text-sm text-muted">{item.contact_name}</span>
                ) : null}
              </div>
              <p className="mt-1.5 text-[15px] leading-relaxed text-ink/90">
                {item.notes}
              </p>
            </div>
          </li>
        )
      })}
    </ol>
  )
}
