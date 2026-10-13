type Props = {
  value: number
  goal: number
  onChange: (next: number) => void
}

export function WaterCounter({ value, goal, onChange }: Props) {
  return (
    <div
      className="rounded-2xl border p-4"
      style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <div className="font-display text-lg font-bold">Vand</div>
          <div className="text-sm text-[var(--muted)]">
            {value} / {goal} glas · {Math.round((Math.min(value, goal) / Math.max(goal, 1)) * 100)}%
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            className="tap grid h-12 w-12 place-items-center rounded-2xl border text-2xl"
            style={{ background: 'var(--bg-2)', borderColor: 'var(--line)' }}
            onClick={() => onChange(Math.max(0, value - 1))}
            aria-label="Fjern et glas"
          >
            −
          </button>
          <button
            type="button"
            className="tap grid h-12 w-12 place-items-center rounded-2xl text-2xl font-bold"
            style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
            onClick={() => onChange(value + 1)}
            aria-label="Tilføj et glas"
          >
            +
          </button>
        </div>
      </div>
      <div className="mt-3 flex flex-wrap gap-1.5">
        {Array.from({ length: goal }, (_, i) => (
          <span
            key={i}
            className="h-2.5 flex-1 min-w-6 rounded-full"
            style={{
              background: i < value ? 'var(--accent)' : 'var(--ring-track)',
            }}
          />
        ))}
      </div>
    </div>
  )
}
