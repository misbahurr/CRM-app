import type {
  CustomerDetail,
  CustomerListResponse,
  Insight,
  InteractionListResponse,
  PriorityFilter,
} from '../types'

const BASE = import.meta.env.VITE_API_BASE_URL ?? '/api'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(init?.headers ?? {}),
    },
  })
  if (!response.ok) {
    const detail = await response.text()
    throw new Error(detail || `Request failed (${response.status})`)
  }
  return response.json() as Promise<T>
}

export const PAGE_SIZE = 20

export const api = {
  listCustomers: (opts?: {
    filter?: PriorityFilter
    limit?: number
    offset?: number
  }) => {
    const params = new URLSearchParams({
      filter: opts?.filter ?? 'all',
      limit: String(opts?.limit ?? PAGE_SIZE),
      offset: String(opts?.offset ?? 0),
    })
    return request<CustomerListResponse>(`/customers?${params}`)
  },
  getCustomer: (id: string) => request<CustomerDetail>(`/customers/${id}`),
  getInsights: (id: string) => request<Insight>(`/customers/${id}/insights`),
  refreshInsights: (id: string) =>
    request<Insight>(`/customers/${id}/insights/refresh`, { method: 'POST' }),
  listInteractions: (customerId: string, opts?: { limit?: number; offset?: number }) => {
    const params = new URLSearchParams({
      customer_id: customerId,
      limit: String(opts?.limit ?? 50),
      offset: String(opts?.offset ?? 0),
    })
    return request<InteractionListResponse>(`/interactions?${params}`)
  },
}
