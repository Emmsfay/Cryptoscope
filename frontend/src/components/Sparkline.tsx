import { LineChart, Line, ResponsiveContainer } from 'recharts'

interface SparklineProps {
  data: number[]
  positive: boolean
}

export function Sparkline({ data, positive }: SparklineProps) {
  if (!data || data.length === 0) return <span style={{ color: '#666' }}>—</span>

  const chartData = data.map(v => ({ v }))
  const color = positive ? '#22c55e' : '#ef4444'

  return (
    <ResponsiveContainer width={100} height={36}>
      <LineChart data={chartData}>
        <Line
          type="monotone"
          dataKey="v"
          stroke={color}
          strokeWidth={1.5}
          dot={false}
          isAnimationActive={false}
        />
      </LineChart>
    </ResponsiveContainer>
  )
}
