import { useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, getOrCreateDay, patchDay } from '../db/db'
import { MUSCLE_LABELS } from '../db/types'
import { formatPrettyDate, todayKey, weekKeys } from '../lib/dates'
import { dayKind, dayKindLabel, pickWorkoutLetter } from '../lib/schedule'
import { HabitToggle } from '../components/HabitToggle'
import { ProgressRing } from '../components/ProgressRing'
import { WaterCounter } from '../components/WaterCounter'
import { WeekStrip } from '../components/WeekStrip'

export function TodayPage() {
  const date = todayKey()
  const kind = dayKind()
  const settings = useLiveQuery(() => db.settings.get('settings'))
  const day = useLiveQuery(() => db.days.get(date), [date])
  const sessions = useLiveQuery(() => db.sessions.toArray()) ?? []
  const exercises = useLiveQuery(() => db.exercises.filter((e) => !e.archived).toArray()) ?? []
  const weekDays = useLiveQuery(() => db.days.bulkGet(weekKeys()), []) ?? []

  useEffect(() => {
    void getOrCreateDay(date)
  }, [date])

  const letter = useMemo(() => pickWorkoutLetter(sessions), [sessions])
  const todaysPlan = useMemo(
    () =>
      exercises
        .filter((e) => e.workout === letter)
        .sort((a, b) => a.order - b.order),
    [exercises, letter],
  )
  const todaySession = sessions.find((s) => s.date === date && s.completed)

  const marks = useMemo(() => {
    const map: Record<string, boolean> = {}
    for (const d of weekDays) {
      if (!d) continue
      map[d.date] = d.creatine && d.waterGlasses >= (settings?.waterGoal ?? 8) && d.alcoholFree
    }
    return map
  }, [weekDays, settings?.waterGoal])

  const waterGoal = settings?.waterGoal ?? 8
  const waterPct = Math.min(1, (day?.waterGlasses ?? 0) / waterGoal)
  const habitScore =
    (day?.creatine ? 1 : 0) + (waterPct >= 1 ? 1 : 0) + (day?.alcoholFree ? 1 : 0)
  const greeting = greetingForHour(new Date().getHours())

  if (!day || !settings) {
    return <PageSkeleton />
  }

  return (
    <div className="space-y-5 pb-2">
      <header className="pt-2">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">STÆRK</p>
        <h1 className="font-display text-4xl font-extrabold leading-none">
          {greeting}, {settings.displayName}
        </h1>
        <p className="mt-1 capitalize text-[var(--muted)]">{formatPrettyDate(new Date())}</p>
      </header>

      <WeekStrip today={date} marks={marks} />

      <section
        className="overflow-hidden rounded-3xl p-5"
        style={{
          background: 'linear-gradient(145deg, color-mix(in oklab, var(--accent) 22%, var(--surface-2)), var(--surface-2))',
          boxShadow: 'var(--shadow)',
        }}
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-[var(--muted)]">
              {kind === 'gym' ? 'Træningsdag' : kind === 'home' ? 'Hjemmekontor' : 'Weekend'}
            </p>
            <h2 className="mt-1 font-display text-2xl font-extrabold leading-tight">
              {kind === 'gym'
                ? todaySession
                  ? `Program ${todaySession.workout} er klaret`
                  : `I dag: program ${letter}`
                : 'Aktiv restitution'}
            </h2>
            <p className="mt-1 text-sm text-[var(--muted)]">{dayKindLabel(kind)}</p>
          </div>
          <ProgressRing
            value={habitScore}
            max={3}
            size={88}
            stroke={8}
            label={`${habitScore}/3`}
            sub="vaner"
          />
        </div>

        {kind === 'gym' ? (
          <div className="mt-4 space-y-2">
            <p className="text-sm text-[var(--muted)]">
              ~45 min · 3 sæt · 8–12 reps · {todaysPlan.map((e) => MUSCLE_LABELS[e.muscleGroup]).join(' · ')}
            </p>
            <div className="flex flex-wrap gap-2">
              {todaysPlan.map((e) => (
                <span
                  key={e.id}
                  className="rounded-full px-3 py-1 text-xs font-semibold"
                  style={{ background: 'var(--bg)', color: 'var(--fg)' }}
                >
                  {e.name}
                </span>
              ))}
            </div>
            <Link
              to={todaySession ? `/traening/${todaySession.id}` : '/traening/session'}
              className="mt-3 flex h-12 items-center justify-center rounded-2xl text-base font-bold"
              style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
            >
              {todaySession ? 'Se dagens pas' : 'Start træning'}
            </Link>
          </div>
        ) : (
          <p className="mt-3 text-sm leading-relaxed">
            Ingen vægtløftning i dag. En gåtur eller en runde golf tæller — og så kreatin, vand og en alkoholfri aften.
          </p>
        )}
      </section>

      <section className="space-y-2.5">
        <h3 className="font-display text-xl font-bold">Dagens vaner</h3>
        <HabitToggle
          checked={day.creatine}
          onChange={(creatine) => void patchDay(date, { creatine })}
          title="Kreatin taget"
          hint="5 g med morgenkaffen eller efter træning"
          icon="🧪"
        />
        <WaterCounter
          value={day.waterGlasses}
          goal={waterGoal}
          onChange={(waterGlasses) => void patchDay(date, { waterGlasses })}
        />
        <HabitToggle
          checked={day.alcoholFree}
          onChange={(alcoholFree) => void patchDay(date, { alcoholFree })}
          title="Alkoholfri dag"
          hint="Søvn, restitution og talje siger tak"
          icon="🚫"
        />
      </section>

      <section
        className="space-y-3 rounded-3xl border p-4"
        style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
      >
        <h3 className="font-display text-xl font-bold">Bevægelse udenfor gym</h3>
        <Field
          label="Skridt (valgfrit)"
          type="number"
          value={day.steps ?? ''}
          placeholder="fx 8500"
          onChange={(v) =>
            void patchDay(date, { steps: v === '' ? undefined : Math.max(0, Number(v) || 0) })
          }
        />
        <Field
          label="Gåtur (minutter)"
          type="number"
          value={day.walkMinutes ?? ''}
          placeholder="fx 40"
          onChange={(v) =>
            void patchDay(date, { walkMinutes: v === '' ? undefined : Math.max(0, Number(v) || 0) })
          }
        />
        <HabitToggle
          checked={day.golf}
          onChange={(golf) => void patchDay(date, { golf })}
          title="Golf i dag"
          hint="Runden tæller som aktiv restitution"
          icon="⛳"
        />
      </section>
    </div>
  )
}

function Field({
  label,
  value,
  onChange,
  placeholder,
  type = 'text',
}: {
  label: string
  value: string | number
  onChange: (v: string) => void
  placeholder?: string
  type?: string
}) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-semibold text-[var(--muted)]">{label}</span>
      <input
        type={type}
        inputMode={type === 'number' ? 'numeric' : undefined}
        value={value}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="h-12 w-full rounded-2xl border px-4 outline-none"
        style={{ background: 'var(--bg)', borderColor: 'var(--line)', color: 'var(--fg)' }}
      />
    </label>
  )
}

function greetingForHour(hour: number): string {
  if (hour < 10) return 'God morgen'
  if (hour < 17) return 'God dag'
  return 'God aften'
}

function PageSkeleton() {
  return (
    <div className="space-y-4 pt-6">
      <div className="h-10 w-48 animate-pulse rounded-xl" style={{ background: 'var(--surface-2)' }} />
      <div className="h-40 animate-pulse rounded-3xl" style={{ background: 'var(--surface-2)' }} />
      <div className="h-16 animate-pulse rounded-2xl" style={{ background: 'var(--surface-2)' }} />
    </div>
  )
}
