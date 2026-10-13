type Props = {
  value: number
  max: number
  size?: number
  stroke?: number
  label?: string
  sub?: string
}

export function ProgressRing({ value, max, size = 112, stroke = 10, label, sub }: Props) {
  const pct = max <= 0 ? 0 : Math.min(1, value / max)
  const r = (size - stroke) / 2
  const c = 2 * Math.PI * r
  const dash = c * pct

  return (
    <div className="relative inline-grid place-items-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="-rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--ring-track)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="var(--accent)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${dash} ${c - dash}`}
          className="transition-[stroke-dasharray] duration-500"
        />
      </svg>
      <div className="absolute inset-0 grid place-items-center text-center">
        <div>
          <div className="font-display text-xl font-extrabold leading-none">{label ?? `${value}`}</div>
          {sub ? <div className="mt-0.5 text-[11px] text-[var(--muted)]">{sub}</div> : null}
        </div>
      </div>
    </div>
  )
}
