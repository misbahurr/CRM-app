export function formatDate(value: string | null | undefined): string {
  if (!value) return '—'
  const iso = value.includes('T') ? value : `${value}T00:00:00`
  return new Date(iso).toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  })
}

export function daysLabel(days: number | null | undefined): string {
  if (days == null) return 'No contact yet'
  if (days === 0) return 'Today'
  if (days === 1) return 'Yesterday'
  return `${days} days ago`
}
