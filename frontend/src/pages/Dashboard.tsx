import { useState, useMemo } from 'react'
import { RefreshCw, Search, TrendingUp, TrendingDown, Activity } from 'lucide-react'
import { usePrices } from '../hooks/usePrices'
import { Sparkline } from '../components/Sparkline'
import { PriceChange } from '../components/PriceChange'
import { CoinChart } from '../components/CoinChart'
import { CoinPrice } from '../services/api'

const CURRENCIES = ['usd', 'eur', 'gbp', 'btc', 'eth']

function formatLargeNumber(n: number | null): string {
  if (n === null) return '—'
  if (n >= 1e12) return `$${(n / 1e12).toFixed(2)}T`
  if (n >= 1e9) return `$${(n / 1e9).toFixed(2)}B`
  if (n >= 1e6) return `$${(n / 1e6).toFixed(2)}M`
  return `$${n.toLocaleString()}`
}

export function Dashboard() {
  const [currency, setCurrency] = useState('usd')
  const [search, setSearch] = useState('')
  const [selectedCoin, setSelectedCoin] = useState<CoinPrice | null>(null)
  const [sortKey, setSortKey] = useState<'market_cap_rank' | 'current_price' | 'price_change_percentage_24h'>('market_cap_rank')
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc')

  const { coins, loading, error, lastUpdated, refresh } = usePrices({
    vs_currency: currency,
    per_page: 100,
    refreshInterval: 30000,
  })

  const filtered = useMemo(() => {
    let list = coins.filter(c =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.symbol.toLowerCase().includes(search.toLowerCase())
    )
    list = [...list].sort((a, b) => {
      const av = a[sortKey] ?? 0
      const bv = b[sortKey] ?? 0
      return sortDir === 'asc' ? (av > bv ? 1 : -1) : (av < bv ? 1 : -1)
    })
    return list
  }, [coins, search, sortKey, sortDir])

  const topGainer = useMemo(() =>
    [...coins].sort((a, b) => (b.price_change_percentage_24h ?? 0) - (a.price_change_percentage_24h ?? 0))[0],
    [coins]
  )
  const topLoser = useMemo(() =>
    [...coins].sort((a, b) => (a.price_change_percentage_24h ?? 0) - (b.price_change_percentage_24h ?? 0))[0],
    [coins]
  )

  const handleSort = (key: typeof sortKey) => {
    if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc')
    else { setSortKey(key); setSortDir('asc') }
  }

  const SortIndicator = ({ k }: { k: typeof sortKey }) =>
    sortKey === k ? <span style={{ marginLeft: 4, opacity: 0.7 }}>{sortDir === 'asc' ? '↑' : '↓'}</span> : null

  return (
    <div style={{ minHeight: '100vh', background: '#080810', color: '#e8e8f0', fontFamily: "'DM Sans', sans-serif" }}>
      {/* Header */}
      <header style={{
        borderBottom: '1px solid #1a1a28',
        padding: '1rem 2rem',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        position: 'sticky', top: 0,
        background: 'rgba(8,8,16,0.95)',
        backdropFilter: 'blur(12px)',
        zIndex: 100,
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          <Activity size={22} color="#7c6af7" />
          <span style={{ fontWeight: 700, fontSize: '1.2rem', letterSpacing: '-0.03em' }}>
            Crypto<span style={{ color: '#7c6af7' }}>Scope</span>
          </span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          {lastUpdated && (
            <span style={{ fontSize: '0.75rem', color: '#555' }}>
              Updated {lastUpdated.toLocaleTimeString()}
            </span>
          )}
          <button
            onClick={refresh}
            disabled={loading}
            style={{
              background: 'none', border: '1px solid #2a2a3a',
              borderRadius: '8px', padding: '0.4rem 0.8rem',
              color: '#888', cursor: 'pointer', display: 'flex',
              alignItems: 'center', gap: '0.4rem', fontSize: '0.8rem',
            }}
          >
            <RefreshCw size={14} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} />
            Refresh
          </button>
        </div>
      </header>

      <main style={{ maxWidth: 1200, margin: '0 auto', padding: '2rem' }}>
        {/* Stats bar */}
        {coins.length > 0 && (
          <div style={{ display: 'flex', gap: '1rem', marginBottom: '2rem', flexWrap: 'wrap' }}>
            {[
              { label: 'Tracking', value: `${coins.length} coins`, icon: <Activity size={14} /> },
              { label: 'Top gainer 24h', value: topGainer ? `${topGainer.symbol.toUpperCase()} +${topGainer.price_change_percentage_24h?.toFixed(2)}%` : '—', icon: <TrendingUp size={14} />, color: '#22c55e' },
              { label: 'Top loser 24h', value: topLoser ? `${topLoser.symbol.toUpperCase()} ${topLoser.price_change_percentage_24h?.toFixed(2)}%` : '—', icon: <TrendingDown size={14} />, color: '#ef4444' },
            ].map(s => (
              <div key={s.label} style={{
                background: '#0f0f1a', border: '1px solid #1e1e2e',
                borderRadius: '10px', padding: '0.75rem 1.2rem',
                display: 'flex', flexDirection: 'column', gap: '0.2rem', flex: '1 1 180px',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem', color: '#555', fontSize: '0.75rem' }}>
                  {s.icon} {s.label}
                </div>
                <div style={{ fontWeight: 600, fontSize: '0.95rem', color: s.color ?? '#e8e8f0' }}>{s.value}</div>
              </div>
            ))}
          </div>
        )}

        {/* Controls */}
        <div style={{ display: 'flex', gap: '1rem', marginBottom: '1.5rem', flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ position: 'relative', flex: '1 1 240px' }}>
            <Search size={14} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: '#555' }} />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search coins..."
              style={{
                width: '100%', paddingLeft: '2rem', paddingRight: '1rem',
                paddingTop: '0.5rem', paddingBottom: '0.5rem',
                background: '#0f0f1a', border: '1px solid #1e1e2e',
                borderRadius: '8px', color: '#e8e8f0', fontSize: '0.9rem',
                outline: 'none', boxSizing: 'border-box',
              }}
            />
          </div>
          <select
            value={currency}
            onChange={e => setCurrency(e.target.value)}
            style={{
              background: '#0f0f1a', border: '1px solid #1e1e2e',
              borderRadius: '8px', color: '#e8e8f0',
              padding: '0.5rem 0.75rem', fontSize: '0.9rem',
              cursor: 'pointer', outline: 'none', textTransform: 'uppercase',
            }}
          >
            {CURRENCIES.map(c => <option key={c} value={c}>{c.toUpperCase()}</option>)}
          </select>
        </div>

        {/* Error */}
        {error && (
          <div style={{
            background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
            borderRadius: '10px', padding: '1rem', marginBottom: '1.5rem', color: '#f87171',
          }}>
            {error}
          </div>
        )}

        {/* Table */}
        <div style={{ background: '#0c0c16', border: '1px solid #1a1a28', borderRadius: '14px', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.875rem' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #1a1a28', color: '#555' }}>
                {[
                  { label: '#', key: 'market_cap_rank' as const, w: 50 },
                  { label: 'Coin', key: null, w: 200 },
                  { label: 'Price', key: 'current_price' as const, w: 130 },
                  { label: '1h', key: null, w: 90 },
                  { label: '24h', key: 'price_change_percentage_24h' as const, w: 90 },
                  { label: '7d', key: null, w: 90 },
                  { label: 'Market Cap', key: null, w: 140 },
                  { label: 'Volume 24h', key: null, w: 130 },
                  { label: '7d chart', key: null, w: 110 },
                ].map(col => (
                  <th
                    key={col.label}
                    onClick={col.key ? () => handleSort(col.key!) : undefined}
                    style={{
                      padding: '0.85rem 1rem', textAlign: col.label === '#' ? 'center' : 'right',
                      fontWeight: 500, fontSize: '0.75rem', letterSpacing: '0.05em',
                      cursor: col.key ? 'pointer' : 'default',
                      userSelect: 'none', whiteSpace: 'nowrap',
                      ...(col.label === 'Coin' ? { textAlign: 'left' } : {}),
                    }}
                  >
                    {col.label}
                    {col.key && <SortIndicator k={col.key} />}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading && coins.length === 0
                ? Array.from({ length: 10 }).map((_, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid #12121e' }}>
                      {Array.from({ length: 9 }).map((_, j) => (
                        <td key={j} style={{ padding: '0.85rem 1rem' }}>
                          <div style={{
                            height: 16, background: '#1a1a28',
                            borderRadius: 4, animation: 'pulse 1.5s ease-in-out infinite',
                            width: j === 1 ? '120px' : '60px',
                          }} />
                        </td>
                      ))}
                    </tr>
                  ))
                : filtered.map((coin, idx) => (
                    <tr
                      key={coin.id}
                      onClick={() => setSelectedCoin(coin)}
                      style={{
                        borderBottom: '1px solid #12121e',
                        cursor: 'pointer',
                        transition: 'background 0.12s',
                      }}
                      onMouseEnter={e => (e.currentTarget.style.background = '#0f0f1c')}
                      onMouseLeave={e => (e.currentTarget.style.background = 'transparent')}
                    >
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'center', color: '#555', fontSize: '0.8rem' }}>
                        {coin.market_cap_rank ?? idx + 1}
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
                          <img src={coin.image} alt={coin.name} style={{ width: 24, height: 24, borderRadius: '50%' }} />
                          <div>
                            <div style={{ fontWeight: 600, color: '#e8e8f0' }}>{coin.name}</div>
                            <div style={{ fontSize: '0.75rem', color: '#555', textTransform: 'uppercase' }}>{coin.symbol}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>
                        {coin.current_price !== null ? `$${coin.current_price.toLocaleString()}` : '—'}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right' }}>
                        <PriceChange value={coin.price_change_percentage_1h_in_currency} />
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right' }}>
                        <PriceChange value={coin.price_change_percentage_24h_in_currency} />
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right' }}>
                        <PriceChange value={coin.price_change_percentage_7d_in_currency} />
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right', color: '#aaa' }}>
                        {formatLargeNumber(coin.market_cap)}
                      </td>
                      <td style={{ padding: '0.85rem 1rem', textAlign: 'right', color: '#aaa' }}>
                        {formatLargeNumber(coin.total_volume)}
                      </td>
                      <td style={{ padding: '0.85rem 1rem' }}>
                        <div style={{ display: 'flex', justifyContent: 'center' }}>
                          <Sparkline
                            data={coin.sparkline_in_7d?.price ?? []}
                            positive={(coin.price_change_percentage_7d_in_currency ?? 0) >= 0}
                          />
                        </div>
                      </td>
                    </tr>
                  ))
              }
            </tbody>
          </table>

          {!loading && filtered.length === 0 && (
            <div style={{ padding: '3rem', textAlign: 'center', color: '#555' }}>
              No coins match "{search}"
            </div>
          )}
        </div>
      </main>

      {selectedCoin && (
        <CoinChart coin={selectedCoin} onClose={() => setSelectedCoin(null)} />
      )}

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&display=swap');
        * { box-sizing: border-box; }
        body { margin: 0; }
        input::placeholder { color: #444; }
        @keyframes spin { to { transform: rotate(360deg); } }
        @keyframes pulse { 0%,100% { opacity: 0.4; } 50% { opacity: 0.8; } }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: #0c0c16; }
        ::-webkit-scrollbar-thumb { background: #2a2a3a; border-radius: 3px; }
      `}</style>
    </div>
  )
}
