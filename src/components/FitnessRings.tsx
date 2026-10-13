type Ring = { value: number; max: number; color: string }

function RingArc({
  size,
  radius,
  stroke,
  value,
  max,
  color,
}: {
  size: number
  radius: number
  stroke: number
  value: number
  max: number
  color: string
}) {
  const pct = max <= 0 ? 0 : Math.min(1, value / max)
  const c = 2 * Math.PI * radius
  const dash = c * pct
  return (
    <>
      <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="var(--ring-track)" strokeWidth={stroke} />
      {pct > 0.02 ? (
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${dash} ${c - dash}`}
          className="transition-[stroke-dasharray] duration-700"
          style={{ filter: `drop-shadow(0 0 5px ${color})` }}
        />
      ) : null}
    </>
  )
}

export function FitnessRings({
  move,
  exercise,
  stand,
  size = 168,
}: {
  move: Ring
  exercise: Ring
  stand: Ring
  size?: number
}) {
  const stroke = size * 0.105
  const gap = stroke * 0.28
  const outer = (size - stroke) / 2 - 1
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <RingArc size={size} radius={outer} stroke={stroke} {...move} />
        <RingArc size={size} radius={outer - stroke - gap} stroke={stroke} {...exercise} />
        <RingArc size={size} radius={outer - (stroke + gap) * 2} stroke={stroke} {...stand} />
      </svg>
    </div>
  )
}

export function ProgressRing({
  value,
  max,
  size = 88,
  stroke = 8,
  color = 'var(--ring-exercise)',
  label,
  sub,
}: {
  value: number
  max: number
  size?: number
  stroke?: number
  color?: string
  label?: string
  sub?: string
}) {
  const pct = max <= 0 ? 0 : Math.min(1, value / max)
  const r = (size - stroke) / 2
  const c = 2 * Math.PI * r
  const dash = c * pct
  return (
    <div className="relative inline-grid place-items-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="var(--ring-track)" strokeWidth={stroke} />
        {pct > 0.02 ? (
          <circle
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            stroke={color}
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={`${dash} ${c - dash}`}
            className="transition-[stroke-dasharray] duration-500"
          />
        ) : null}
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        <div>
          <div className="text-[17px] font-semibold leading-none">{label ?? `${value}`}</div>
          {sub ? <div className="mt-0.5 text-[11px] text-[var(--muted)]">{sub}</div> : null}
        </div>
      </div>
    </div>
  )
}
