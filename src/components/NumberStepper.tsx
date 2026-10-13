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
      <span className="mb-1 block text-[11px] font-semibold uppercase tracking-wide text-[var(--muted)]">
        {label}
      </span>
      <div
        className="flex items-center overflow-hidden rounded-2xl border"
        style={{ borderColor: 'var(--line)', background: 'var(--bg)' }}
      >
        <button
          type="button"
          className="tap grid h-12 w-12 place-items-center text-xl"
          onClick={() => onChange(Math.max(min, Number((value - step).toFixed(2))))}
          aria-label={`Mindsk ${label}`}
        >
          −
        </button>
        <input
          type="number"
          inputMode="decimal"
          className="h-12 w-full min-w-0 bg-transparent text-center text-lg font-bold outline-none"
          value={Number.isFinite(value) ? value : 0}
          onChange={(e) => onChange(Math.max(min, Number(e.target.value) || 0))}
        />
        <button
          type="button"
          className="tap grid h-12 w-12 place-items-center text-xl"
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
