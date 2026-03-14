import { useState, useEffect, useCallback } from 'react'
import { cryptoApi, CoinPrice } from '../services/api'

interface UsePricesOptions {
  vs_currency?: string
  per_page?: number
  refreshInterval?: number // ms, 0 = no auto-refresh
}

interface UsePricesResult {
  coins: CoinPrice[]
  loading: boolean
  error: string | null
  lastUpdated: Date | null
  refresh: () => void
}

export function usePrices({
  vs_currency = 'usd',
  per_page = 50,
  refreshInterval = 30000,
}: UsePricesOptions = {}): UsePricesResult {
  const [coins, setCoins] = useState<CoinPrice[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)

  const fetch = useCallback(async () => {
    try {
      setError(null)
      const data = await cryptoApi.getPrices({ vs_currency, per_page })
      setCoins(data)
      setLastUpdated(new Date())
    } catch (err: any) {
      setError(err?.response?.data?.detail ?? 'Failed to fetch prices')
    } finally {
      setLoading(false)
    }
  }, [vs_currency, per_page])

  useEffect(() => {
    fetch()
    if (refreshInterval > 0) {
      const id = setInterval(fetch, refreshInterval)
      return () => clearInterval(id)
    }
  }, [fetch, refreshInterval])

  return { coins, loading, error, lastUpdated, refresh: fetch }
}
