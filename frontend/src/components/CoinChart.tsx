import { useState } from 'react'
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer
} from 'recharts'
import { X } from 'lucide-react'
import { useCoinChart } from '../hooks/useCoinChart'
import { CoinPrice } from '../services/api'

interface CoinChartProps {
  coin: CoinPrice
  onClose: () => void
}

const RANGES = [
  { label: '1D', days: 1 },
  { label: '7D', days: 7 },
  { label: '30D', days: 30 },
  { label: '90D', days: 90 },
]

export function CoinChart({ coin, onClose }: CoinChartProps) {
  const [days, setDays] = useState(7)
  const { chart, loading } = useCoinChart(coin.id, days)

  const chartData = chart?.prices.map(([ts, price]) => ({
    date: new Date(ts).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    price,
  })) ?? []

  const isPositive = (coin.price_change_percentage_7d_in_currency ?? 0) >= 0
  const color = isPositive ? '#22c55e' : '#ef4444'

  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 1000, padding: '1rem',
    }}>
      <div style={{
        background: '#0f0f13', border: '1px solid #2a2a35',
        borderRadius: '16px', padding: '1.5rem',
        width: '100%', maxWidth: '680px',
      }}>
        {/* Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <img src={coin.image} alt={coin.name} style={{ width: 32, height: 32 }} />
            <div>
              <div style={{ fontWeight: 600, color: '#fff', fontSize: '1.1rem' }}>{coin.name}</div>
              <div style={{ color: '#888', fontSize: '0.8rem', textTransform: 'uppercase' }}>{coin.symbol}</div>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#888' }}>
            <X size={20} />
          </button>
        </div>

        {/* Price */}
        <div style={{ marginBottom: '1rem' }}>
          <span style={{ fontSize: '1.8rem', fontWeight: 700, color: '#fff' }}>
            ${coin.current_price?.toLocaleString()}
          </span>
        </div>

        {/* Range selector */}
        <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '1rem' }}>
          {RANGES.map(r => (
            <button
              key={r.days}
              onClick={() => setDays(r.days)}
              style={{
                padding: '0.25rem 0.75rem',
                borderRadius: '6px',
                border: 'none',
                cursor: 'pointer',
                fontWeight: 500,
                fontSize: '0.8rem',
                background: days === r.days ? color : '#1e1e2a',
                color: days === r.days ? '#fff' : '#888',
                transition: 'all 0.15s',
              }}
            >
              {r.label}
            </button>
          ))}
        </div>

        {/* Chart */}
        {loading ? (
          <div style={{ height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#666' }}>
            Loading chart...
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={color} stopOpacity={0.3} />
                  <stop offset="95%" stopColor={color} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#1e1e2a" />
              <XAxis dataKey="date" tick={{ fill: '#666', fontSize: 11 }} tickLine={false} axisLine={false} />
              <YAxis
                tick={{ fill: '#666', fontSize: 11 }}
                tickLine={false}
                axisLine={false}
                tickFormatter={v => `$${v >= 1000 ? (v / 1000).toFixed(1) + 'k' : v.toLocaleString()}`}
                width={70}
              />
              <Tooltip
                contentStyle={{ background: '#1a1a24', border: '1px solid #2a2a35', borderRadius: 8 }}
                labelStyle={{ color: '#888' }}
                itemStyle={{ color: color }}
                formatter={(v: number) => [`$${v.toLocaleString()}`, 'Price']}
              />
              <Area type="monotone" dataKey="price" stroke={color} strokeWidth={2} fill="url(#colorGrad)" dot={false} />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  )
}
