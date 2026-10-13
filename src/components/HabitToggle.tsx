type Props = {
  checked: boolean
  onChange: (next: boolean) => void
  title: string
  hint: string
  icon: string
}

export function HabitToggle({ checked, onChange, title, hint, icon }: Props) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className="flex w-full items-center gap-3 rounded-2xl border px-4 py-3.5 text-left transition"
      style={{
        background: checked ? 'color-mix(in oklab, var(--accent) 16%, var(--surface-2))' : 'var(--surface-2)',
        borderColor: checked ? 'color-mix(in oklab, var(--accent) 45%, var(--line))' : 'var(--line)',
      }}
    >
      <span
        className="grid h-12 w-12 shrink-0 place-items-center rounded-2xl text-xl"
        style={{ background: 'var(--bg-2)' }}
      >
        {icon}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block font-display text-base font-bold leading-tight">{title}</span>
        <span className="block text-sm text-[var(--muted)]">{hint}</span>
      </span>
      <span
        className="grid h-8 w-8 shrink-0 place-items-center rounded-full border-2 text-sm font-bold"
        style={{
          borderColor: checked ? 'var(--accent)' : 'var(--line)',
          background: checked ? 'var(--accent)' : 'transparent',
          color: checked ? 'var(--accent-fg)' : 'var(--muted)',
        }}
      >
        {checked ? '✓' : ''}
      </span>
    </button>
  )
}
