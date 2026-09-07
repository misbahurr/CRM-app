export type CustomerStatus = 'prospect' | 'customer'
export type InteractionType = 'email' | 'call' | 'meeting' | 'note'
export type PriorityFilter = 'all' | 'attention' | 'prospects' | 'customers'

export type CustomerSummary = {
  id: string
  name: string
  status: CustomerStatus
  created_at: string
  priority_score: number
  priority_reason: string
  last_interaction_at: string | null
  days_since_last: number | null
}

export type FilterCounts = {
  all: number
  attention: number
  prospects: number
  customers: number
}

export type CustomerListResponse = {
  items: CustomerSummary[]
  total: number
  limit: number
  offset: number
  has_more: boolean
  counts: FilterCounts
}

export type Contact = {
  id: string
  customer_id: string
  name: string
  email: string | null
  role: string | null
}

export type Interaction = {
  id: string
  customer_id: string
  contact_id: string
  contact_name: string | null
  type: InteractionType
  occurred_at: string
  notes: string | null
}

export type InteractionListResponse = {
  items: Interaction[]
  total: number
  limit: number
  offset: number
  has_more: boolean
}

export type CustomerDetail = {
  id: string
  name: string
  status: CustomerStatus
  created_at: string
  contacts: Contact[]
  interactions: Interaction[]
}

export type Insight = {
  customer_id: string
  summary: string | null
  next_action: string | null
  drafted_message: string | null
  priority_score: number | null
  priority_reason: string | null
  generated_at: string | null
}

export function priorityLevel(score: number): 'high' | 'medium' | 'low' {
  if (score >= 70) return 'high'
  if (score >= 40) return 'medium'
  return 'low'
}
