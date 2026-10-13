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
    <div className="grid grid-cols-7 px-1 py-2">
      {keys.map((key, i) => {
        const active = key === today
        const done = Boolean(marks[key])
        return (
          <div key={key} className="text-center">
            <div className="text-[11px] capitalize text-[var(--muted)]">{WEEKDAY_SHORT[i]}</div>
            <div
              className="mx-auto mt-1 grid h-8 w-8 place-items-center rounded-full text-[17px] font-semibold"
              style={{
                background: active ? 'var(--pink)' : 'transparent',
                color: active ? '#fff' : 'var(--fg)',
              }}
            >
              {format(new Date(key), 'd', { locale: da })}
            </div>
            <div
              className="mx-auto mt-1 h-1 w-1 rounded-full"
              style={{ background: done ? (active ? '#fff' : 'var(--accent)') : 'transparent' }}
            />
          </div>
        )
      })}
    </div>
  )
}
