type Props = {
  value: number
  onChange: (next: number) => void
  step?: number
  min?: number
  label: string
  suffix?: string
}

export function NumberStepper({ value, onChange, step = 1, min = 0, label, suffix }: Props) {
  return (
    <label className="block min-w-0 flex-1">
      <span className="mb-1 block text-[12px] text-[var(--muted)]">{label}</span>
      <div className="flex items-center overflow-hidden rounded-[12px]" style={{ background: 'var(--fill)' }}>
        <button
          type="button"
          className="press grid h-11 w-11 place-items-center text-[22px]"
          onClick={() => onChange(Math.max(min, Number((value - step).toFixed(2))))}
          aria-label={`Mindsk ${label}`}
        >
          −
        </button>
        <input
          type="number"
          inputMode="decimal"
          className="h-11 w-full min-w-0 bg-transparent text-center text-[22px] font-semibold tabular-nums outline-none"
          value={Number.isFinite(value) ? value : 0}
          onChange={(e) => onChange(Math.max(min, Number(e.target.value) || 0))}
        />
        <button
          type="button"
          className="press grid h-11 w-11 place-items-center text-[22px]"
          onClick={() => onChange(Number((value + step).toFixed(2)))}
          aria-label={`Øg ${label}`}
        >
          +
        </button>
      </div>
      {suffix ? <span className="sr-only">{suffix}</span> : null}
    </label>
  )
}
