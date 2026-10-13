import { Link } from 'react-router-dom'
import type { ReactNode } from 'react'
import { BackIcon, ChevronIcon } from './Icons'

export function PageHeader({
  title,
  subtitle,
  backTo,
  backLabel = 'Tilbage',
  trailing,
}: {
  title: string
  subtitle?: string
  backTo?: string
  backLabel?: string
  trailing?: ReactNode
}) {
  return (
    <header className="px-1 pt-1">
      {backTo ? (
        <Link to={backTo} className="press mb-1 inline-flex items-center gap-1 text-[17px]" style={{ color: 'var(--blue)' }}>
          <BackIcon />
          {backLabel}
        </Link>
      ) : null}
      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <h1 className="large-title">{title}</h1>
          {subtitle ? <p className="mt-1 text-[15px] leading-snug text-[var(--muted)]">{subtitle}</p> : null}
        </div>
        {trailing}
      </div>
    </header>
  )
}

export function SectionLabel({ children }: { children: ReactNode }) {
  return <div className="section-label">{children}</div>
}

export function Group({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <div className={`group ${className}`}>{children}</div>
}

export function Row({
  children,
  onClick,
  to,
  className = '',
}: {
  children: ReactNode
  onClick?: () => void
  to?: string
  className?: string
}) {
  const cls = `row press flex min-h-12 w-full items-center gap-3 px-4 py-3 text-left ${className}`
  if (to) {
    return (
      <Link to={to} className={cls}>
        {children}
      </Link>
    )
  }
  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={cls}>
        {children}
      </button>
    )
  }
  return <div className={cls}>{children}</div>
}

export function RowGlyph({ children, tint = 'var(--accent)' }: { children: ReactNode; tint?: string }) {
  return (
    <span
      className="grid h-7 w-7 shrink-0 place-items-center rounded-[7px] text-white"
      style={{ background: tint }}
    >
      {children}
    </span>
  )
}

export function RowChevron() {
  return <ChevronIcon />
}

export function PrimaryButton({
  children,
  onClick,
  to,
  disabled,
}: {
  children: ReactNode
  onClick?: () => void
  to?: string
  disabled?: boolean
}) {
  const cls =
    'press flex h-12 w-full items-center justify-center rounded-[12px] text-[17px] font-semibold disabled:opacity-50'
  const style = { background: 'var(--accent)', color: 'var(--accent-fg)' }
  if (to) {
    return (
      <Link to={to} className={cls} style={style}>
        {children}
      </Link>
    )
  }
  return (
    <button type="button" disabled={disabled} onClick={onClick} className={cls} style={style}>
      {children}
    </button>
  )
}

export function PlainButton({
  children,
  onClick,
  danger,
}: {
  children: ReactNode
  onClick?: () => void
  danger?: boolean
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="press flex h-12 w-full items-center justify-center text-[17px]"
      style={{ color: danger ? '#ff453a' : 'var(--blue)' }}
    >
      {children}
    </button>
  )
}

export function Segmented<T extends string>({
  value,
  onChange,
  options,
}: {
  value: T
  onChange: (v: T) => void
  options: { value: T; label: string }[]
}) {
  return (
    <div className="grid rounded-[9px] p-[3px]" style={{ background: 'var(--fill)', gridTemplateColumns: `repeat(${options.length}, 1fr)` }}>
      {options.map((opt) => {
        const on = opt.value === value
        return (
          <button
            key={opt.value}
            type="button"
            onClick={() => onChange(opt.value)}
            className="press h-8 rounded-[7px] text-[13px] font-semibold"
            style={{
              background: on ? 'var(--bg-elevated)' : 'transparent',
              boxShadow: on ? '0 1px 3px rgba(0,0,0,0.12)' : undefined,
              color: 'var(--fg)',
            }}
          >
            {opt.label}
          </button>
        )
      })}
    </div>
  )
}

export function IosToggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={(e) => {
        e.stopPropagation()
        onChange(!checked)
      }}
      className="relative h-[31px] w-[51px] shrink-0 rounded-full transition-colors duration-200"
      style={{ background: checked ? 'var(--accent)' : 'var(--fill-strong)' }}
    >
      <span
        className="absolute top-[2px] h-[27px] w-[27px] rounded-full bg-white shadow-md transition-[left] duration-200"
        style={{ left: checked ? '22px' : '2px' }}
      />
    </button>
  )
}

export function IosStepper({
  value,
  onChange,
  step = 1,
  min = 0,
}: {
  value: number
  onChange: (n: number) => void
  step?: number
  min?: number
}) {
  return (
    <div className="flex overflow-hidden rounded-[9px]" style={{ background: 'var(--fill)' }}>
      <button
        type="button"
        className="press grid h-8 w-9 place-items-center text-[18px]"
        onClick={() => onChange(Math.max(min, Number((value - step).toFixed(2))))}
        aria-label="Mindsk"
      >
        −
      </button>
      <span className="w-px self-stretch" style={{ background: 'var(--hairline)' }} />
      <button
        type="button"
        className="press grid h-8 w-9 place-items-center text-[18px]"
        onClick={() => onChange(Number((value + step).toFixed(2)))}
        aria-label="Øg"
      >
        +
      </button>
    </div>
  )
}

export function EmptyState({ children }: { children: ReactNode }) {
  return (
    <p className="px-5 py-8 text-center text-[15px] text-[var(--muted)]">{children}</p>
  )
}
