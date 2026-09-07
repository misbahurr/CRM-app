import type { CustomerDetail, CustomerSummary, Insight, Interaction } from '../types'

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

export const api = {
  listCustomers: () => request<CustomerSummary[]>('/customers'),
  getCustomer: (id: string) => request<CustomerDetail>(`/customers/${id}`),
  getInsights: (id: string) => request<Insight>(`/customers/${id}/insights`),
  refreshInsights: (id: string) =>
    request<Insight>(`/customers/${id}/insights/refresh`, { method: 'POST' }),
  listInteractions: (customerId: string) =>
    request<Interaction[]>(`/interactions?customer_id=${encodeURIComponent(customerId)}`),
}
