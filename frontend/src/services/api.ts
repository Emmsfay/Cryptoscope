import axios from 'axios'

const api = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

export interface SparklineData {
  price: number[]
}

export interface CoinPrice {
  id: string
  symbol: string
  name: string
  image: string
  current_price: number | null
  market_cap: number | null
  market_cap_rank: number | null
  total_volume: number | null
  price_change_percentage_1h_in_currency: number | null
  price_change_percentage_24h_in_currency: number | null
  price_change_percentage_7d_in_currency: number | null
  price_change_percentage_24h: number | null
  circulating_supply: number | null
  sparkline_in_7d: SparklineData | null
}

export interface MarketChart {
  prices: [number, number][]
  market_caps: [number, number][]
  total_volumes: [number, number][]
}

export interface SearchResult {
  id: string
  name: string
  symbol: string
  thumb: string
  market_cap_rank: number
}

export const cryptoApi = {
  getPrices: (params?: {
    vs_currency?: string
    per_page?: number
    page?: number
    order?: string
  }) => api.get<CoinPrice[]>('/prices/', { params }).then(r => r.data),

  searchCoins: (q: string) =>
    api.get<SearchResult[]>('/coins/search', { params: { q } }).then(r => r.data),

  getCoinDetail: (id: string) =>
    api.get(`/coins/${id}`).then(r => r.data),

  getCoinChart: (id: string, days: number = 7, vs_currency: string = 'usd') =>
    api.get<MarketChart>(`/coins/${id}/chart`, { params: { days, vs_currency } }).then(r => r.data),
}
