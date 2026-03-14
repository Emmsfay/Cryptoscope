interface PriceChangeProps {
  value: number | null
}

export function PriceChange({ value }: PriceChangeProps) {
  if (value === null || value === undefined) return <span style={{ color: '#666' }}>—</span>

  const positive = value >= 0
  const color = positive ? '#22c55e' : '#ef4444'
  const sign = positive ? '+' : ''

  return (
    <span style={{ color, fontVariantNumeric: 'tabular-nums', fontWeight: 500 }}>
      {sign}{value.toFixed(2)}%
    </span>
  )
}
