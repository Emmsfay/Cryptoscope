import { useState, useEffect } from 'react'
import { cryptoApi, MarketChart } from '../services/api'

export function useCoinChart(coinId: string | null, days: number = 7) {
  const [chart, setChart] = useState<MarketChart | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!coinId) return
    setLoading(true)
    setError(null)
    cryptoApi
      .getCoinChart(coinId, days)
      .then(setChart)
      .catch(e => setError(e?.message ?? 'Chart load failed'))
      .finally(() => setLoading(false))
  }, [coinId, days])

  return { chart, loading, error }
}
