import { Link, useParams } from 'react-router-dom'
import { useMemo } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { db } from '../db/db'
import { MUSCLE_LABELS } from '../db/types'
import { formatDayShort } from '../lib/dates'
import { lastForExercise } from '../lib/progression'

export function ExercisePage() {
  const { exerciseId } = useParams()
  const exercise = useLiveQuery(() => (exerciseId ? db.exercises.get(exerciseId) : undefined), [exerciseId])
  const sessions = useLiveQuery(() => db.sessions.orderBy('date').toArray()) ?? []

  const points = useMemo(() => {
    if (!exerciseId) return []
    return sessions
      .filter((s) => s.completed)
      .map((s) => {
        const block = s.exercises.find((e) => e.exerciseId === exerciseId)
        const done = block?.sets.filter((x) => x.done)
        if (!done?.length) return null
        const top = done.reduce((b, x) => (x.weight > b.weight ? x : b), done[0])
        const volume = done.reduce((n, x) => n + x.weight * x.reps, 0)
        return {
          date: formatDayShort(s.date),
          key: s.date,
          weight: top.weight,
          reps: top.reps,
          seconds: top.reps,
          volume,
        }
      })
      .filter((x): x is NonNullable<typeof x> => x !== null)
  }, [sessions, exerciseId])

  if (!exercise) return <p className="pt-8 text-[var(--muted)]">Finder øvelsen…</p>

  const last = lastForExercise(sessions, exercise.id)
  const isHold = exercise.logType === 'seconds'

  return (
    <div className="space-y-4 pb-2">
      <header className="pt-2">
        <Link to="/traening" className="text-sm font-semibold text-[var(--muted)]">
          ← Træning
        </Link>
        <h1 className="mt-2 font-display text-4xl font-extrabold leading-none">{exercise.name}</h1>
        <p className="mt-1 text-[var(--muted)]">
          {MUSCLE_LABELS[exercise.muscleGroup]} · Program {exercise.workout}
        </p>
      </header>

      <section className="rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
        <h2 className="font-display text-lg font-bold">{isHold ? 'Bedste tid' : 'Topvægt'}</h2>
        {points.length === 0 ? (
          <p className="mt-2 text-sm text-[var(--muted)]">Ingen data endnu. Log et pas, så kommer grafen.</p>
        ) : (
          <div className="mt-2 h-56">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={points}>
                <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
                <XAxis dataKey="date" tick={{ fill: 'var(--muted)', fontSize: 11 }} />
                <YAxis tick={{ fill: 'var(--muted)', fontSize: 11 }} width={36} />
                <Tooltip
                  contentStyle={{
                    background: 'var(--surface)',
                    border: '1px solid var(--line)',
                    borderRadius: 12,
                    color: 'var(--fg)',
                  }}
                />
                <Line
                  type="monotone"
                  dataKey={isHold ? 'seconds' : 'weight'}
                  stroke="var(--accent)"
                  strokeWidth={3}
                  dot={{ r: 4, fill: 'var(--accent)' }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
        {last ? (
          <p className="mt-2 text-sm">
            Seneste: {last.sets.map((s) => (isHold ? `${s.reps}s` : `${s.weight} kg × ${s.reps}`)).join(' · ')}
          </p>
        ) : null}
      </section>

      <section className="space-y-2">
        <h2 className="font-display text-xl font-bold">Pas</h2>
        {points.length === 0 ? (
          <p className="text-sm text-[var(--muted)]">Ingen historik.</p>
        ) : (
          <ul className="space-y-2">
            {[...sessions]
              .reverse()
              .filter((s) => s.exercises.some((e) => e.exerciseId === exercise.id && e.sets.some((x) => x.done)))
              .map((s) => {
                const block = s.exercises.find((e) => e.exerciseId === exercise.id)
                return (
                  <li
                    key={s.id}
                    className="rounded-2xl border px-4 py-3"
                    style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
                  >
                    <div className="font-display font-bold">{formatDayShort(s.date)}</div>
                    <div className="text-sm text-[var(--muted)]">
                      {block?.sets
                        .filter((x) => x.done)
                        .map((x) => (isHold ? `${x.reps}s` : `${x.weight}×${x.reps}`))
                        .join(' · ')}
                    </div>
                  </li>
                )
              })}
          </ul>
        )}
      </section>
    </div>
  )
}
