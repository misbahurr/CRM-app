import type { CustomerDetail } from '../types'
import { formatDate } from '../lib/format'
import { StatusBadge } from './StatusBadge'

export function CustomerHeader({ customer }: { customer: CustomerDetail }) {
  return (
    <div>
      <div className="flex flex-wrap items-center gap-2">
        <h1 className="font-heading text-3xl text-ink">{customer.name}</h1>
        <StatusBadge status={customer.status} />
      </div>
      <p className="mt-1 text-sm text-muted">
        On the books since {formatDate(customer.created_at)}
      </p>

      <div className="mt-4">
        <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-muted">
          People at this practice
        </p>
        <ul className="mt-2 grid gap-2 sm:grid-cols-2">
          {customer.contacts.map((contact) => (
            <li
              key={contact.id}
              className="rounded-xl border border-line bg-card px-3 py-2.5"
            >
              <p className="font-medium text-ink">{contact.name}</p>
              <p className="text-sm text-muted">
                {contact.role || 'Contact'}
                {contact.email ? ` · ${contact.email}` : ''}
              </p>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
