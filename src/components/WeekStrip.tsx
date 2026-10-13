import { format } from 'date-fns'
import { da } from 'date-fns/locale'
import { weekKeys } from '../lib/dates'
import { WEEKDAY_SHORT } from '../db/types'

type Props = {
  today: string
  marks?: Record<string, boolean>
}

export function WeekStrip({ today, marks = {} }: Props) {
  const keys = weekKeys()
  return (
    <div className="grid grid-cols-7 gap-1.5">
      {keys.map((key, i) => {
        const active = key === today
        const done = Boolean(marks[key])
        return (
          <div
            key={key}
            className="rounded-2xl px-1 py-2 text-center"
            style={{
              background: active ? 'var(--accent)' : 'var(--surface-2)',
              color: active ? 'var(--accent-fg)' : 'var(--fg)',
              boxShadow: active ? 'var(--shadow)' : undefined,
            }}
          >
            <div className="text-[10px] font-semibold uppercase tracking-wide opacity-80">
              {WEEKDAY_SHORT[i]}
            </div>
            <div className="font-display text-lg font-extrabold leading-none">
              {format(new Date(key), 'd', { locale: da })}
            </div>
            <div
              className="mx-auto mt-1 h-1.5 w-1.5 rounded-full"
              style={{
                background: done ? (active ? 'var(--accent-fg)' : 'var(--accent)') : 'transparent',
              }}
            />
          </div>
        )
      })}
    </div>
  )
}
