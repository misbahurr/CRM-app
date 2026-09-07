import { BrowserRouter, Link, Route, Routes } from 'react-router-dom'
import { Dashboard } from './pages/Dashboard'
import { CustomerDetail } from './pages/CustomerDetail'

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-svh">
        <header className="border-b border-line bg-card/90 backdrop-blur">
          <div className="mx-auto flex max-w-3xl items-center justify-between px-5 py-3.5">
            <Link to="/" className="no-underline">
              <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-teal-dark">
                Dental book
              </p>
              <p className="font-heading text-xl leading-tight text-ink">Micro-CRM</p>
            </Link>
            <p className="max-w-[11rem] text-right text-sm leading-snug text-muted">
              Who needs a conversation today
            </p>
          </div>
        </header>
        <main className="mx-auto max-w-3xl px-5 py-8">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/customers/:id" element={<CustomerDetail />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}
