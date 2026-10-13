import { useParams } from 'react-router-dom'
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
import { Group, PageHeader } from '../components/ui'

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
    <div className="space-y-5 pb-2">
      <PageHeader
        title={exercise.name}
        subtitle={`${MUSCLE_LABELS[exercise.muscleGroup]} · Program ${exercise.workout}`}
        backTo="/traening"
        backLabel="Træning"
      />

      <Group className="p-4">
        <h2 className="text-[20px] font-semibold">{isHold ? 'Bedste tid' : 'Topvægt'}</h2>
        {points.length === 0 ? (
          <p className="mt-2 text-sm text-[var(--muted)]">Ingen data endnu. Log et pas, så kommer grafen.</p>
        ) : (
          <div className="mt-2 h-56">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={points}>
                <CartesianGrid stroke="var(--hairline)" strokeDasharray="3 3" />
                <XAxis dataKey="date" tick={{ fill: 'var(--muted)', fontSize: 11 }} />
                <YAxis tick={{ fill: 'var(--muted)', fontSize: 11 }} width={36} />
                <Tooltip
                  contentStyle={{
                    background: 'var(--bg-elevated)',
                    border: '0.5px solid var(--hairline)',
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
      </Group>

      <Group>
        {points.length === 0 ? (
          <p className="px-4 py-6 text-[15px] text-[var(--muted)]">Ingen historik.</p>
        ) : (
          [...sessions]
            .reverse()
            .filter((s) => s.exercises.some((e) => e.exerciseId === exercise.id && e.sets.some((x) => x.done)))
            .map((s) => {
              const block = s.exercises.find((e) => e.exerciseId === exercise.id)
              return (
                <div key={s.id} className="row px-4 py-3">
                  <div className="text-[17px]">{formatDayShort(s.date)}</div>
                  <div className="text-[13px] text-[var(--muted)]">
                    {block?.sets
                      .filter((x) => x.done)
                      .map((x) => (isHold ? `${x.reps}s` : `${x.weight}×${x.reps}`))
                      .join(' · ')}
                  </div>
                </div>
              )
            })
        )}
      </Group>
    </div>
  )
}
