import { useEffect, useMemo } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db, getOrCreateDay, patchDay } from '../db/db'
import { MUSCLE_LABELS } from '../db/types'
import { formatPrettyDate, todayKey, weekKeys } from '../lib/dates'
import { dayKind, dayKindLabel, pickWorkoutLetter } from '../lib/schedule'
import { HabitToggle } from '../components/HabitToggle'
import { FitnessRings } from '../components/FitnessRings'
import { WaterCounter } from '../components/WaterCounter'
import { WeekStrip } from '../components/WeekStrip'
import { Group, PageHeader, PrimaryButton, Row, SectionLabel } from '../components/ui'
import { BanIcon, FlagIcon, PillIcon } from '../components/Icons'

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
    () => exercises.filter((e) => e.workout === letter).sort((a, b) => a.order - b.order),
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
  const greeting = greetingForHour(new Date().getHours())

  if (!day || !settings) {
    return (
      <div className="space-y-3 pt-6">
        <div className="h-10 w-40 animate-pulse rounded-lg" style={{ background: 'var(--bg-elevated)' }} />
        <div className="h-44 animate-pulse rounded-[12px]" style={{ background: 'var(--bg-elevated)' }} />
      </div>
    )
  }

  return (
    <div className="space-y-6 pb-2">
      <PageHeader
        title={`${greeting}, ${settings.displayName}`}
        subtitle={capitalize(formatPrettyDate(new Date()))}
      />

      <Group>
        <WeekStrip today={date} marks={marks} />
      </Group>

      <Group className="px-5 py-5">
        <div className="flex items-center gap-5">
          <FitnessRings
            move={{ value: day.creatine ? 1 : 0, max: 1, color: 'var(--ring-move)' }}
            exercise={{ value: day.waterGlasses, max: waterGoal, color: 'var(--ring-exercise)' }}
            stand={{ value: day.alcoholFree ? 1 : 0, max: 1, color: 'var(--ring-stand)' }}
            size={148}
          />
          <div className="min-w-0 flex-1">
            <p className="text-[13px] font-medium" style={{ color: 'var(--pink)' }}>
              {kind === 'gym' ? 'Træning' : kind === 'home' ? 'Hjemmekontor' : 'Weekend'}
            </p>
            <h2 className="mt-0.5 text-[22px] font-bold leading-tight tracking-tight">
              {kind === 'gym'
                ? todaySession
                  ? `Program ${todaySession.workout} er klaret`
                  : `Program ${letter}`
                : 'Aktiv restitution'}
            </h2>
            <p className="mt-1 text-[13px] leading-snug text-[var(--muted)]">{dayKindLabel(kind)}</p>
            <ul className="mt-3 space-y-1 text-[12px]">
              <Legend color="var(--ring-move)" label="Kreatin" done={day.creatine} />
              <Legend
                color="var(--ring-exercise)"
                label={`Vand ${day.waterGlasses}/${waterGoal}`}
                done={day.waterGlasses >= waterGoal}
              />
              <Legend color="var(--ring-stand)" label="Alkoholfri" done={day.alcoholFree} />
            </ul>
          </div>
        </div>

        {kind === 'gym' ? (
          <div className="mt-5">
            <p className="mb-2 text-[13px] text-[var(--muted)]">
              ~45 min · {todaysPlan.map((e) => MUSCLE_LABELS[e.muscleGroup]).join(' · ')}
            </p>
            <PrimaryButton to={todaySession ? `/traening/${todaySession.id}` : '/traening/session'}>
              {todaySession ? 'Se dagens pas' : 'Start træning'}
            </PrimaryButton>
          </div>
        ) : (
          <p className="mt-4 text-[15px] leading-relaxed text-[var(--muted)]">
            Ingen vægtløftning i dag. En gåtur eller en runde golf tæller — og så kreatin, vand og en alkoholfri aften.
          </p>
        )}
      </Group>

      <div>
        <SectionLabel>Dagens vaner</SectionLabel>
        <Group>
          <HabitToggle
            checked={day.creatine}
            onChange={(creatine) => void patchDay(date, { creatine })}
            title="Kreatin taget"
            hint="5 g med morgenkaffen eller efter træning"
            tint="var(--pink)"
            glyph={<PillIcon color="#fff" />}
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
            tint="var(--orange)"
            glyph={<BanIcon color="#fff" />}
          />
        </Group>
      </div>

      <div>
        <SectionLabel>Bevægelse</SectionLabel>
        <Group>
          <Row>
            <span className="flex-1 text-[17px]">Skridt</span>
            <input
              className="ios-input max-w-32"
              type="number"
              inputMode="numeric"
              placeholder="Valgfrit"
              value={day.steps ?? ''}
              onChange={(e) =>
                void patchDay(date, {
                  steps: e.target.value === '' ? undefined : Math.max(0, Number(e.target.value) || 0),
                })
              }
            />
          </Row>
          <Row>
            <span className="flex-1 text-[17px]">Gåtur</span>
            <input
              className="ios-input max-w-32"
              type="number"
              inputMode="numeric"
              placeholder="Minutter"
              value={day.walkMinutes ?? ''}
              onChange={(e) =>
                void patchDay(date, {
                  walkMinutes: e.target.value === '' ? undefined : Math.max(0, Number(e.target.value) || 0),
                })
              }
            />
          </Row>
          <HabitToggle
            checked={day.golf}
            onChange={(golf) => void patchDay(date, { golf })}
            title="Golf i dag"
            hint="Runden tæller som aktiv restitution"
            tint="var(--accent)"
            glyph={<FlagIcon color="#fff" />}
          />
        </Group>
      </div>
    </div>
  )
}

function Legend({ color, label, done }: { color: string; label: string; done: boolean }) {
  return (
    <li className="flex items-center gap-2">
      <span className="h-2 w-2 rounded-full" style={{ background: color }} />
      <span className="text-[var(--muted)]">
        {label}
        {done ? ' ✓' : ''}
      </span>
    </li>
  )
}

function greetingForHour(hour: number): string {
  if (hour < 10) return 'God morgen'
  if (hour < 17) return 'God dag'
  return 'God aften'
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
