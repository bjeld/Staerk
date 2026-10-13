import { useMemo, useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { addMonths, format } from 'date-fns'
import { da } from 'date-fns/locale'
import { db } from '../db/db'
import { MUSCLE_GROUPS, MUSCLE_LABELS, WEEKDAY_SHORT, type DayLog } from '../db/types'
import { monthGrid, todayKey, weekKeys } from '../lib/dates'
import { weeklySetVolume } from '../lib/progression'
import { ProgressRing } from '../components/ProgressRing'
import { Group, PageHeader } from '../components/ui'

export function HabitsPage() {
  const settings = useLiveQuery(() => db.settings.get('settings'))
  const days = useLiveQuery(() => db.days.orderBy('date').toArray()) ?? []
  const sessions = useLiveQuery(() => db.sessions.toArray()) ?? []
  const exercises = useLiveQuery(() => db.exercises.toArray()) ?? []
  const [cursor, setCursor] = useState(() => new Date())

  const waterGoal = settings?.waterGoal ?? 8
  const today = todayKey()
  const cells = monthGrid(cursor)

  const byDate = useMemo(() => Object.fromEntries(days.map((d) => [d.date, d])), [days])
  const sessionByDate = useMemo(() => {
    const map: Record<string, boolean> = {}
    for (const s of sessions) {
      if (s.completed) map[s.date] = true
    }
    return map
  }, [sessions])

  const creatineStreak = streak(days, (d) => d.creatine, today)
  const waterStreak = streak(days, (d) => d.waterGlasses >= waterGoal, today)
  const soberStreak = streak(days, (d) => d.alcoholFree, today)
  const gymStreak = trainingStreak(sessions, today)

  const week = weekKeys()
  const weekScore = week.reduce((n, key) => {
    const d = byDate[key]
    if (!d) return n
    return n + (d.creatine ? 1 : 0) + (d.waterGlasses >= waterGoal ? 1 : 0) + (d.alcoholFree ? 1 : 0)
  }, 0)

  const muscleMap = useMemo(
    () => Object.fromEntries(exercises.map((e) => [e.id, e.muscleGroup])),
    [exercises],
  )
  const volume = weeklySetVolume(sessions, week[0], week[6], (id) => muscleMap[id])
  const volumeData = MUSCLE_GROUPS.map((g) => ({
    name: MUSCLE_LABELS[g],
    sæt: volume[g] ?? 0,
  }))

  return (
    <div className="space-y-6 pb-2">
      <PageHeader title="Vaner" subtitle="En uge ad gangen. Konsistens slår hero-pas." />

      <section className="grid grid-cols-2 gap-3">
        <StatRing title="Kreatin" value={creatineStreak} unit="dage" color="var(--ring-move)" />
        <StatRing title="Vandmål" value={waterStreak} unit="dage" color="var(--ring-exercise)" />
        <StatRing title="Alkoholfri" value={soberStreak} unit="dage" color="var(--ring-stand)" />
        <StatRing title="Gym-række" value={gymStreak} unit="pas" color="var(--orange)" />
      </section>

      <Group className="p-4">
        <div className="flex items-center justify-between">
          <h2 className="text-[20px] font-semibold">Denne uge</h2>
          <span className="text-sm text-[var(--muted)]">{weekScore}/21 vaner</span>
        </div>
        <div className="mt-3 overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead>
              <tr className="text-[var(--muted)]">
                <th className="pb-2 font-medium">Dag</th>
                <th className="pb-2 font-medium">K</th>
                <th className="pb-2 font-medium">V</th>
                <th className="pb-2 font-medium">A</th>
                <th className="pb-2 font-medium">T</th>
              </tr>
            </thead>
            <tbody>
              {week.map((key, i) => {
                const d = byDate[key]
                return (
                  <tr key={key} className="border-t" style={{ borderColor: 'var(--hairline)' }}>
                    <td className="py-2.5 font-semibold capitalize">
                      {WEEKDAY_SHORT[i]} {key === today ? '· i dag' : ''}
                    </td>
                    <td>{mark(Boolean(d?.creatine))}</td>
                    <td>{mark(Boolean(d && d.waterGlasses >= waterGoal))}</td>
                    <td>{mark(Boolean(d?.alcoholFree))}</td>
                    <td>{mark(Boolean(sessionByDate[key]))}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
        <p className="mt-2 text-xs text-[var(--muted)]">K = kreatin · V = vandmål · A = alkoholfri · T = træning</p>
      </Group>

      <Group className="p-4">
        <h2 className="text-[20px] font-semibold">Ugens sæt pr. muskel</h2>
        {volumeData.every((d) => d.sæt === 0) ? (
          <p className="mt-2 text-sm text-[var(--muted)]">Ingen sæt denne uge endnu.</p>
        ) : (
          <div className="mt-2 h-56">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={volumeData}>
                <CartesianGrid stroke="var(--hairline)" strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fill: 'var(--muted)', fontSize: 11 }} />
                <YAxis allowDecimals={false} tick={{ fill: 'var(--muted)', fontSize: 11 }} width={28} />
                <Tooltip
                  contentStyle={{
                    background: 'var(--bg-elevated)',
                    border: '0.5px solid var(--hairline)',
                    borderRadius: 12,
                  }}
                />
                <Bar dataKey="sæt" fill="var(--accent)" radius={[8, 8, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </Group>

      <Group className="p-4">
        <div className="mb-3 flex items-center justify-between">
          <button type="button" className="press h-11 px-3 text-[22px]" onClick={() => setCursor((c) => addMonths(c, -1))}>
            ‹
          </button>
          <h2 className="text-[20px] font-semibold capitalize">
            {format(cursor, 'MMMM yyyy', { locale: da })}
          </h2>
          <button type="button" className="press h-11 px-3 text-[22px]" onClick={() => setCursor((c) => addMonths(c, 1))}>
            ›
          </button>
        </div>
        <div className="mb-1 grid grid-cols-7 text-center text-[10px] font-bold uppercase text-[var(--muted)]">
          {WEEKDAY_SHORT.map((d) => (
            <div key={d}>{d}</div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1">
          {cells.map((key, i) => {
            if (!key) return <div key={`e-${i}`} />
            const d = byDate[key]
            const score =
              (d?.creatine ? 1 : 0) +
              (d && d.waterGlasses >= waterGoal ? 1 : 0) +
              (d?.alcoholFree ? 1 : 0) +
              (sessionByDate[key] ? 1 : 0)
            const isToday = key === today
            return (
              <div
                key={key}
                className="grid aspect-square place-items-center rounded-xl text-xs font-bold"
                style={{
                  background: score === 0 ? 'var(--fill)' : `color-mix(in oklab, var(--accent) ${18 + score * 16}%, var(--bg))`,
                  outline: isToday ? '2px solid var(--accent)' : undefined,
                }}
                title={`${key}: ${score}/4`}
              >
                {Number(key.slice(-2))}
              </div>
            )
          })}
        </div>
      </Group>
    </div>
  )
}

function StatRing({
  title,
  value,
  unit,
  color,
}: {
  title: string
  value: number
  unit: string
  color: string
}) {
  return (
    <Group className="p-3 text-center">
      <ProgressRing value={Math.min(value, 14)} max={14} size={88} stroke={8} color={color} label={`${value}`} sub={unit} />
      <div className="mt-1 text-[13px] font-medium">{title}</div>
    </Group>
  )
}

function mark(ok: boolean): string {
  return ok ? '●' : '○'
}

function streak(days: DayLog[], pred: (d: DayLog) => boolean, today: string): number {
  const map = new Map(days.map((d) => [d.date, d]))
  let count = 0
  const cursor = new Date(`${today}T12:00:00`)
  for (let i = 0; i < 400; i++) {
    const key = todayKeyFrom(cursor)
    const row = map.get(key)
    if (!row || !pred(row)) break
    count += 1
    cursor.setDate(cursor.getDate() - 1)
  }
  return count
}

function trainingStreak(sessions: { date: string; completed: boolean }[], today: string): number {
  const dates = new Set(sessions.filter((s) => s.completed).map((s) => s.date))
  const trainingDays: string[] = []
  const cursor = new Date(`${today}T12:00:00`)
  for (let i = 0; i < 180; i++) {
    const day = cursor.getDay()
    if (day === 1 || day === 3 || day === 5) {
      trainingDays.push(todayKeyFrom(cursor))
    }
    cursor.setDate(cursor.getDate() - 1)
  }
  let count = 0
  for (const key of trainingDays) {
    if (key === today && !dates.has(key)) continue
    if (!dates.has(key)) break
    count += 1
  }
  return count
}

function todayKeyFrom(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}
