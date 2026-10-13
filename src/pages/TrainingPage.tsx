import { useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import { MUSCLE_LABELS, type WorkoutLetter } from '../db/types'
import { formatDayShort, todayKey } from '../lib/dates'
import { dayKind, pickWorkoutLetter } from '../lib/schedule'

export function TrainingPage() {
  const exercises = useLiveQuery(() => db.exercises.filter((e) => !e.archived).toArray()) ?? []
  const sessions = useLiveQuery(() => db.sessions.orderBy('date').reverse().toArray()) ?? []
  const letter = pickWorkoutLetter(sessions)
  const kind = dayKind()
  const date = todayKey()
  const todayDone = sessions.find((s) => s.date === date && s.completed)

  const byLetter = (w: WorkoutLetter) =>
    exercises.filter((e) => e.workout === w).sort((a, b) => a.order - b.order)

  const programA = byLetter('A')
  const programB = byLetter('B')

  const recent = useMemo(() => sessions.filter((s) => s.completed).slice(0, 8), [sessions])

  return (
    <div className="space-y-5 pb-2">
      <header className="pt-2">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Program</p>
        <h1 className="font-display text-4xl font-extrabold leading-none">Træning</h1>
        <p className="mt-2 text-sm leading-relaxed text-[var(--muted)]">
          Fuldkropsstyrke 3× om ugen, ~45 min. Man/ons/fre tidligt på jobbet. Program A og B skiftes, så
          alle muskelgrupper bliver ramt med lidt variation.
        </p>
      </header>

      <section
        className="rounded-3xl p-5"
        style={{
          background: 'linear-gradient(150deg, color-mix(in oklab, var(--accent) 20%, var(--surface-2)), var(--surface-2))',
        }}
      >
        <p className="text-xs font-bold uppercase tracking-widest text-[var(--muted)]">
          {kind === 'gym' ? 'Næste pas' : 'Næste gym-dag'}
        </p>
        <h2 className="mt-1 font-display text-3xl font-extrabold">
          {todayDone ? `I dag: program ${todayDone.workout} ✓` : `Program ${letter}`}
        </h2>
        <p className="mt-1 text-sm text-[var(--muted)]">
          {kind === 'gym'
            ? 'Log sæt, mens pulsen stadig er oppe — så husker du tallene.'
            : 'I dag er restitution. Programmet venter til næste mandag, onsdag eller fredag.'}
        </p>
        <div className="mt-4 flex gap-2">
          <Link
            to="/traening/session"
            className="flex h-12 flex-1 items-center justify-center rounded-2xl font-bold"
            style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
          >
            {todayDone ? 'Nyt pas alligevel' : 'Start pas'}
          </Link>
          <Link
            to="/traening/program"
            className="flex h-12 flex-1 items-center justify-center rounded-2xl border font-bold"
            style={{ borderColor: 'var(--line)', background: 'var(--surface-2)' }}
          >
            Rediger øvelser
          </Link>
        </div>
      </section>

      <ProgramCard letter="A" active={letter === 'A' && !todayDone} exercises={programA} />
      <ProgramCard letter="B" active={letter === 'B' && !todayDone} exercises={programB} />

      <section>
        <div className="mb-2 flex items-end justify-between">
          <h3 className="font-display text-xl font-bold">Historik</h3>
          <span className="text-sm text-[var(--muted)]">{recent.length} seneste</span>
        </div>
        {recent.length === 0 ? (
          <Empty>Ingen pas logget endnu. Første uge er den sværeste — så bliver det vane.</Empty>
        ) : (
          <ul className="space-y-2">
            {recent.map((s) => {
              const doneSets = s.exercises.reduce((n, e) => n + e.sets.filter((x) => x.done).length, 0)
              return (
                <li key={s.id}>
                  <Link
                    to={`/traening/${s.id}`}
                    className="flex items-center justify-between rounded-2xl border px-4 py-3"
                    style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
                  >
                    <span>
                      <span className="block font-display font-bold">
                        Program {s.workout} · {formatDayShort(s.date)}
                      </span>
                      <span className="text-sm text-[var(--muted)]">{doneSets} sæt gennemført</span>
                    </span>
                    <span className="text-[var(--muted)]">›</span>
                  </Link>
                </li>
              )
            })}
          </ul>
        )}
      </section>
    </div>
  )
}

function ProgramCard({
  letter,
  active,
  exercises,
}: {
  letter: WorkoutLetter
  active: boolean
  exercises: { id: string; name: string; muscleGroup: keyof typeof MUSCLE_LABELS; defaultSets: number; defaultRepsMin: number; defaultRepsMax: number; logType: string }[]
}) {
  return (
    <section
      className="rounded-3xl border p-4"
      style={{
        background: 'var(--surface-2)',
        borderColor: active ? 'var(--accent)' : 'var(--line)',
      }}
    >
      <div className="mb-3 flex items-center justify-between">
        <h3 className="font-display text-2xl font-extrabold">Program {letter}</h3>
        {active ? (
          <span
            className="rounded-full px-2.5 py-1 text-xs font-bold"
            style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
          >
            I dag
          </span>
        ) : null}
      </div>
      <ol className="space-y-2">
        {exercises.map((e, i) => (
          <li key={e.id} className="flex items-start gap-3">
            <span
              className="grid h-8 w-8 shrink-0 place-items-center rounded-xl text-sm font-bold"
              style={{ background: 'var(--bg-2)' }}
            >
              {i + 1}
            </span>
            <span className="min-w-0">
              <span className="block font-semibold">{e.name}</span>
              <span className="text-sm text-[var(--muted)]">
                {MUSCLE_LABELS[e.muscleGroup]} · {e.defaultSets} ×{' '}
                {e.logType === 'seconds'
                  ? `${e.defaultRepsMin}–${e.defaultRepsMax} sek`
                  : `${e.defaultRepsMin}–${e.defaultRepsMax}`}
              </span>
            </span>
          </li>
        ))}
      </ol>
    </section>
  )
}

function Empty({ children }: { children: string }) {
  return (
    <p
      className="rounded-2xl border border-dashed px-4 py-6 text-sm text-[var(--muted)]"
      style={{ borderColor: 'var(--line)' }}
    >
      {children}
    </p>
  )
}
