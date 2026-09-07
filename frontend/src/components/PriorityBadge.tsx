import { priorityLevel } from '../types'

const COPY = {
  high: {
    label: 'Needs attention',
    className: 'bg-red-50 text-urgent ring-red-100',
  },
  medium: {
    label: 'Check in soon',
    className: 'bg-amber-50 text-watch ring-amber-100',
  },
  low: {
    label: 'Healthy',
    className: 'bg-lime-50 text-healthy ring-lime-100',
  },
} as const

export function PriorityBadge({ score }: { score: number }) {
  const level = priorityLevel(score)
  const { label, className } = COPY[level]
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ${className}`}
    >
      {label}
      <span className="tabular-nums opacity-70">{score}</span>
    </span>
  )
}
